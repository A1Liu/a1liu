const std = @import("std");
const root = @import("root");
const liu = @import("./lib.zig");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Obj = enum(u32) {
    // These are kept up to date with components/wasm.ts

    jsundefined,
    jsnull,

    log,
    info,
    warn,
    err,
    success,

    U8Array,
    F32Array,

    _,
};

const ext = struct {
    extern fn makeString(message: [*]const u8, length: usize) Obj;
    extern fn makeView(o: Obj, message: ?*const anyopaque, length: usize) Obj;

    extern fn makeArray() Obj;
    extern fn makeObj() Obj;
    extern fn arrayPush(arr: Obj, obj: Obj) void;
    extern fn objSet(obj: Obj, key: Obj, value: Obj) void;

    extern fn watermark() Obj;
    extern fn setWatermark(objIndex: Obj) void;

    extern fn objMapStringEncode(idx: Obj) usize;
    extern fn objMapLen(idx: Obj) usize;
    extern fn readObjMapBytes(idx: Obj, begin: [*]u8) void;

    extern fn postMessage(tagIdx: Obj, id: Obj) void;
    extern fn exit(objIndex: Obj) noreturn;
};

pub const watermark = ext.watermark;
pub const setWatermark = ext.setWatermark;

pub const out = struct {
    pub const array = ext.makeArray;
    pub const obj = ext.makeObj;
    pub const arrayPush = ext.arrayPush;
    pub const objSet = ext.objSet;

    pub fn slice(data: anytype) Obj {
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
        return switch (T) {
            u8 => ext.makeView(.U8Array, ptr, len),
            f32 => ext.makeView(.F32Array, ptr, len),
            else => unreachable,
        };
    }

    pub fn string(a: []const u8) Obj {
        return ext.makeString(a.ptr, a.len);
    }

    pub fn fmt(comptime format: []const u8, args: anytype) Obj {
        var _temp = liu.Temp.init();
        const temp = _temp.allocator();
        defer _temp.deinit();

        const allocResult = std.fmt.allocPrint(temp, format, args);
        const data = allocResult catch @panic("failed to print");

        return ext.makeString(data.ptr, data.len);
    }

    pub fn post(level: Obj, comptime format: []const u8, args: anytype) void {
        if (builtin.target.cpu.arch != .wasm32) {
            std.log.info(format, args);
            return;
        }

        const object = fmt(format, args);
        ext.postMessage(level, object);

        ext.setWatermark(object);
    }
};

pub const in = struct {
    pub fn bytes(obj: Obj, alloc: Allocator) ![]u8 {
        if (builtin.target.cpu.arch != .wasm32) return &.{};
        const len = ext.objMapLen(obj);
        const data = try alloc.alloc(u8, len);

        ext.readObjMapBytes(obj, data.ptr);

        return data;
    }

    pub fn string(obj: Obj, alloc: Allocator) ![]u8 {
        if (builtin.target.cpu.arch != .wasm32) return &.{};
        const len = ext.objMapStringEncode(obj);
        const data = try alloc.alloc(u8, len);

        ext.readObjMapBytes(obj, data.ptr);

        return data;
    }
};

pub fn exit(msg: []const u8) noreturn {
    const obj = ext.makeString(msg.ptr, msg.len);
    return ext.exit(obj);
}

const CommandBuffer = liu.RingBuffer(root.WasmCommand, 64);
var initialized: bool = false;

var cmd_bump: liu.Bump = undefined;
var commands: CommandBuffer = undefined;

const CmdAlloc = cmd_bump.allocator();

pub fn initIfNecessary() void {
    if (builtin.target.cpu.arch != .wasm32) {
        return;
    }

    if (!initialized) {
        cmd_bump = liu.Bump.init(4096, liu.Pages);
        commands = CommandBuffer.init();

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

    out.post(level_obj, fmt ++ "\n", args);
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);

    if (builtin.target.cpu.arch != .wasm32) {
        std.builtin.default_panic(msg, error_return_trace);
    }

    _ = error_return_trace;

    exit(msg);
}
