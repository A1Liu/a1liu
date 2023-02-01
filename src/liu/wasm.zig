const std = @import("std");
const liu = @import("./lib.zig");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Field = std.builtin.Type.StructField;
const ArrayList = std.ArrayList;
const wasm = @This();

// NOTE: this is i32 because Obj can be negative when put in the objMap
pub const Obj = enum(i32) {
    // These are kept up to date with src/wasm.ts
    jsundefined = 0,
    jsnull,
    jstrue,
    jsfalse,

    U8Array,
    F32Array,

    // TODO: There's a finite number of falsy values; we can store them all
    // as enum constants:
    //
    // https://developer.mozilla.org/en-US/docs/Glossary/Falsy

    jsEmptyString,

    log,
    info,
    warn,
    err,
    success,

    _,

    const Self = @This();

    pub const objLen = ext.objLen;
    pub const objSet = ext.objSet;
    pub const arrayPush = ext.arrayPush;
    pub const delete = ext.deleteObj;

    // pub fn Await(self: Self) Self {
    //     var output: wasm.Obj = undefined;

    //     suspend {
    //         const frame = @as(anyframe, @frame());
    //         const opaque_frame = @ptrCast(*const anyopaque, frame);
    //         ext.awaitHook(self, &output, opaque_frame);
    //     }

    //     return output;
    // }
};

// TODO why is this i32?
const Watermark = enum(i32) { _ };

// export fn resumePromise(val: *align(4) const anyopaque, output_slot: *Obj, obj: Obj) void {
//     output_slot.* = obj;
//
//     resume @ptrCast(anyframe, val);
// }

const ext = struct {
    extern fn awaitHook(self: Obj, output: *Obj, slot: *align(4) const anyopaque) void;

    // extern fn boolEval(id: Obj) bool;

    extern fn makeNumber(number: f64, is_temp: bool) Obj;
    extern fn makeU32(number: u32, is_temp: bool) Obj;
    extern fn makeBool(number: bool, is_temp: bool) Obj;
    extern fn makeString(message: [*]const u8, length: usize, is_temp: bool) Obj;
    extern fn makeView(o: Obj, message: ?*const anyopaque, length: usize, is_temp: bool) Obj;

    extern fn makeArray(is_temp: bool) Obj;
    extern fn makeObj(is_temp: bool) Obj;

    extern fn arrayPush(arr: Obj, obj: Obj) void;
    extern fn objSet(obj: Obj, key: Obj, value: Obj) void;

    extern fn watermark() Watermark;
    extern fn setWatermark(watermark: Watermark) void;
    extern fn deleteObj(obj: Obj) void;

    extern fn encodeString(idx: Obj) usize;
    extern fn exactExpFloatFormat(value: f64, is_temp: bool) Obj;
    extern fn fixedFormatFloat(value: f64, decimal_places: u32, is_temp: bool) Obj;
    extern fn parseFloat(obj: Obj) f64;

    extern fn objLen(idx: Obj) u32;
    extern fn readBytes(idx: Obj, begin: [*]u8) void;

    extern fn postMessage(tagIdx: Obj, id: Obj) void;
    extern fn pushMessage(tagIdx: Obj, id: Obj) void;
    extern fn exit(objIndex: Obj) noreturn;
};

comptime {
    @export(liuWasmErrorCode, .{ .name = "liuWasmErrorCode", .linkage = .Strong });
}

var error_code: ?u32 = null;
fn liuWasmErrorCode(code: u32) callconv(.C) void {
    error_code = code;
}

pub const watermark = ext.watermark;
pub const setWatermark = ext.setWatermark;

pub const pushMessage = ext.pushMessage;
pub const postMessage = ext.postMessage;

pub const Lifetime = enum {
    manual,
    temp,

    fn isTemp(self: @This()) bool {
        return self == .temp;
    }
};

// Copied from std
fn parseInfOrNan(comptime T: type, s: []const u8, negative: bool) ?T {
    // inf/infinity; infxxx should only consume inf.
    if (std.ascii.startsWithIgnoreCase(s, "inf")) {
        const n: usize = if (std.ascii.startsWithIgnoreCase(s[3..], "inity")) 8 else 3;
        if (n != s.len) return null;

        return if (!negative) std.math.inf(T) else -std.math.inf(T);
    }

    if (std.ascii.startsWithIgnoreCase(s, "nan")) {
        if (s.len != 3) return null;
        return std.math.nan(T);
    }

    return null;
}

pub fn parseFloat(bytes: []const u8) std.fmt.ParseFloatError!f64 {
    if (bytes.len == 0) {
        return error.InvalidCharacter;
    }

    var i: usize = 0;
    const negative = bytes[i] == '-';
    if (negative or bytes[i] == '+') {
        i += 1;
    }

    if (bytes.len == i) {
        return error.InvalidCharacter;
    }

    if (parseInfOrNan(f64, bytes[i..], negative)) |val| {
        return val;
    }

    const mark = watermark();
    defer setWatermark(mark);

    const obj = make.string(.temp, bytes);
    const val = ext.parseFloat(obj);
    if (std.math.isNan(val)) {
        return error.InvalidCharacter;
    }

    return val;
}

var format_buffer: [128]u8 = undefined;

pub const make = struct {
    pub fn number(life: Lifetime, n: f64) Obj {
        return ext.makeNumber(n, life.isTemp());
    }

    pub fn integer(life: Lifetime, n: anytype) Obj {
        switch (@TypeOf(n)) {
            u32 => return ext.makeU32(n, life.isTemp()),
            else => @compileError("invalid integer type"),
        }
    }

    pub fn slice(life: Lifetime, data: anytype) Obj {
        const ptr: ?*const anyopaque = ptr: {
            switch (@typeInfo(@TypeOf(data))) {
                .Array => {},
                .Pointer => |info| switch (info.size) {
                    .One => switch (@typeInfo(info.child)) {
                        .Array => break :ptr data,
                        else => {},
                    },
                    .Many, .C => {},
                    .Slice => break :ptr data.ptr,
                },
                else => {},
            }

            @compileError("Need to pass a slice or array");
        };

        const len = data.len;

        const T = std.meta.Elem(@TypeOf(data));
        const is_temp = life.isTemp();
        return switch (T) {
            u8 => ext.makeView(.U8Array, ptr, len, is_temp),
            f32 => ext.makeView(.F32Array, ptr, len, is_temp),
            else => unreachable,
        };
    }

    pub fn fmt(life: Lifetime, comptime format: []const u8, args: anytype) Obj {
        static_buffer: {
            var buffer_alloc = FixedBufferAllocator.init(&format_buffer);
            const alloc = buffer_alloc.allocator();
            const data = std.fmt.allocPrint(alloc, format, args) catch
                break :static_buffer;
            return string(life, data);
        }

        const temp = liu.Temp();
        defer temp.deinit();

        const allocResult = std.fmt.allocPrint(temp.alloc, format, args);
        const data = allocResult catch @panic("failed to print");

        return string(life, data);
    }

    pub fn string(life: Lifetime, a: []const u8) Obj {
        if (a.len == 0) return .jsEmptyString;
        return ext.makeString(a.ptr, a.len, life.isTemp());
    }

    pub fn array(life: Lifetime) Obj {
        return ext.makeArray(life.isTemp());
    }

    pub fn obj(life: Lifetime) Obj {
        return ext.makeObj(life.isTemp());
    }

    pub fn exactExpFloatPrint(life: Lifetime, value: f64) Obj {
        return ext.exactExpFloatFormat(value, life.isTemp());
    }

    pub fn fixedFloatPrint(life: Lifetime, value: f64, places: u32) Obj {
        return ext.fixedFormatFloat(value, places, life.isTemp());
    }
};

pub fn post(level: Obj, comptime format: []const u8, args: anytype) void {
    if (builtin.target.cpu.arch != .wasm32) {
        std.log.info(format, args);
        return;
    }

    const mark = watermark();
    defer setWatermark(mark);

    const object = make.fmt(.temp, format, args);
    ext.postMessage(level, object);
}

pub const in = struct {
    pub fn bytes(byte_object: Obj, alloc: Allocator) ![]u8 {
        return alignedBytes(byte_object, alloc, null);
    }

    pub fn alignedBytes(
        byte_object: Obj,
        alloc: Allocator,
        comptime alignment: ?u29,
    ) ![]align(alignment orelse 1) u8 {
        if (builtin.target.cpu.arch != .wasm32) return &.{};

        defer ext.deleteObj(byte_object);

        const len = ext.objLen(byte_object);
        const data = try alloc.alignedAlloc(u8, alignment, len);

        ext.readBytes(byte_object, data.ptr);

        return data;
    }

    pub fn string(string_object: Obj, alloc: Allocator) ![]u8 {
        if (builtin.target.cpu.arch != .wasm32) return &.{};

        defer ext.deleteObj(string_object);

        const len = ext.encodeString(string_object);
        const data = try alloc.alloc(u8, len);

        ext.readBytes(string_object, data.ptr);

        return data;
    }
};

pub fn exit(msg: []const u8) noreturn {
    const exit_message = wasm.make.string(.temp, msg);
    ext.exit(exit_message);
}

// TODO maybe this is just straight up not necessary
var initialized: bool = false;
pub fn initIfNecessary() void {
    if (builtin.target.cpu.arch != .wasm32) {
        return;
    }

    if (!initialized) {
        initialized = true;
    }
}

pub const std_options = struct {
    pub fn logFn(
        comptime message_level: std.log.Level,
        comptime scope: @Type(.EnumLiteral),
        comptime fmt: []const u8,
        args: anytype,
    ) void {
        if (builtin.target.cpu.arch != .wasm32) {
            std.log.defaultLog(message_level, scope, fmt, args);
            return;
        }

        if (@enumToInt(message_level) > @enumToInt(std.options.log_level)) {
            return;
        }

        const level_obj: Obj = switch (message_level) {
            .debug => .info,
            .info => .info,
            .warn => .warn,
            .err => .err,
        };

        post(level_obj, fmt ++ "\n", args);
    }
};

// pub const strip_debug_info = true;
// pub const have_error_return_tracing = false;

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, idk: ?usize) noreturn {
    @setCold(true);

    _ = idk;

    if (builtin.target.cpu.arch != .wasm32) {
        std.builtin.default_panic(msg, error_return_trace);
    }

    exit(msg);
}

const TableField = struct {
    name: []const u8,
    value: []const u8,
};

fn getFieldsForTable(comptime table_info: anytype) []const TableField {
    const InfoType = @TypeOf(table_info);

    var fields: []const TableField = &.{};
    switch (@typeInfo(InfoType)) {
        .Type => {},

        .Struct => |info| {
            for (info.fields) |field| {
                fields = fields ++ &[_]TableField{.{
                    .name = field.name,
                    .value = @field(table_info, field.name),
                }};
            }

            return fields;
        },

        else => |data| @compileError("unsupported input to StringTable: " ++ @tagName(data)),
    }

    switch (@typeInfo(table_info)) {
        .Enum => |info| {
            const variants = info.fields;

            for (variants) |variant| {
                fields = fields ++ &[_]TableField{.{
                    .name = variant.name,
                    .value = variant.name,
                }};
            }

            return fields;
        },

        else => |data| @compileError("unsupported input to StringTable: " ++ @tagName(data)),
    }
}

pub fn StringTable(comptime table_info: anytype) type {
    const fields = getFieldsForTable(table_info);

    var struct_fields: []const Field = &.{};
    for (fields) |field| {
        struct_fields = struct_fields ++ &[_]Field{.{
            .name = field.name,
            .type = Obj,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(Obj),
        }};
    }

    const Data = @Type(.{ .Struct = .{
        .layout = .Auto,
        .decls = &.{},
        .is_tuple = false,
        .fields = struct_fields,
    } });

    return struct {
        pub const Keys = Data;

        pub fn init() Data {
            var output: Data = undefined;

            inline for (fields) |field| {
                @field(output, field.name) = make.string(.manual, field.value);
            }

            return output;
        }
    };
}
