const std = @import("std");
const root = @import("root");
const liu = @import("./lib.zig");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const wasm = @This();

pub const Obj = enum(u32) {
    // These are kept up to date with src/wasm.ts
    jsundefined,
    jsnull,
    jsEmptyString,

    log,
    info,
    warn,
    err,
    success,

    U8Array,
    F32Array,

    _,

    pub const objSet = ext.objSet;
    pub const arrayPush = ext.arrayPush;
};

const Watermark = enum(i32) { _ };

const ext = struct {
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
    extern fn decimalFormatFloat(value: f64, is_temp: bool) Obj;
    extern fn parseFloat(obj: Obj) f64;

    extern fn objLen(idx: Obj) usize;
    extern fn readBytes(idx: Obj, begin: [*]u8) void;

    extern fn postMessage(tagIdx: Obj, id: Obj) void;
    extern fn exit(objIndex: Obj) noreturn;
};

pub const watermark = ext.watermark;
pub const setWatermark = ext.setWatermark;

pub const Lifetime = enum {
    manual,
    temp,

    fn isTemp(self: @This()) bool {
        return self == .temp;
    }
};

pub fn parseFloat(bytes: []const u8) f64 {
    const mark = watermark();
    defer setWatermark(mark);

    const obj = make.string(.temp, bytes);
    return ext.parseFloat(obj);
}

pub const make = struct {
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
        const mark = liu.TempMark;
        defer liu.TempMark = mark;

        const allocResult = std.fmt.allocPrint(liu.Temp, format, args);
        const data = allocResult catch @panic("failed to print");

        return ext.makeString(data.ptr, data.len, life.isTemp());
    }

    pub fn string(life: Lifetime, a: []const u8) Obj {
        return ext.makeString(a.ptr, a.len, life.isTemp());
    }

    pub fn array(life: Lifetime) Obj {
        return ext.makeArray(life.isTemp());
    }

    pub fn obj(life: Lifetime) Obj {
        return ext.makeObj(life.isTemp());
    }

    pub fn floatPrint(life: Lifetime, value: f64) Obj {
        return ext.decimalFormatFloat(value, life.isTemp());
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

pub const delete = ext.deleteObj;
pub fn deleteMany(obj_slice: []const Obj) void {
    for (obj_slice) |o| {
        delete(o);
    }
}

pub const out = struct {
    pub inline fn array() Obj {
        return wasm.make.array(.temp);
    }

    pub inline fn obj() Obj {
        return wasm.make.obj(.temp);
    }

    pub inline fn slice(data: anytype) Obj {
        return wasm.make.slice(.temp, data);
    }

    pub inline fn string(a: []const u8) Obj {
        return wasm.make.string(.temp, a);
    }

    pub inline fn fmt(comptime format: []const u8, args: anytype) Obj {
        return wasm.make.fmt(.temp, format, args);
    }

    pub fn floatPrint(value: f64) Obj {
        return wasm.make.floatPrint(.temp, value);
    }
};

pub const in = struct {
    pub fn bytes(byte_object: Obj, alloc: Allocator) ![]u8 {
        return alignedBytes(byte_object, alloc, null);
    }

    pub fn alignedBytes(byte_object: Obj, alloc: Allocator, comptime alignment: ?u29) ![]align(alignment orelse 1) u8 {
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
    return ext.exit(exit_message);
}

var initialized: bool = false;

pub fn initIfNecessary() void {
    if (builtin.target.cpu.arch != .wasm32) {
        return;
    }

    if (!initialized) {
        initialized = true;
    }
}

pub const strip_debug_info = true;
pub const have_error_return_tracing = false;

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime fmt: []const u8,
    args: anytype,
) void {
    if (builtin.target.cpu.arch != .wasm32) {
        std.log.defaultLog(message_level, scope, fmt, args);
        return;
    }

    _ = scope;

    if (@enumToInt(message_level) > @enumToInt(std.log.level)) {
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

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);

    if (builtin.target.cpu.arch != .wasm32) {
        std.builtin.default_panic(msg, error_return_trace);
    }

    _ = error_return_trace;

    exit(msg);
}
