const std = @import("std");
const root = @import("root");
const liu = @import("./lib.zig");
const builtin = @import("builtin");

// building array of objects:

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Obj = enum(u32) {
    // These are kept up to date with components/wasm.ts
    log,
    info,
    warn,
    err,
    success,

    String,
    U8Array,
    // makeF32Array,

    _,
};

extern fn bytesExt(o: Obj, message: ?*const anyopaque, length: usize) Obj;

pub extern fn makeArray() Obj;
pub extern fn makeObj() Obj;
pub extern fn arrayPush(arr: Obj, obj: Obj) void;
pub extern fn objSet(obj: Obj, key: Obj, value: Obj) void;

pub extern fn watermarkObj() Obj;
pub extern fn clearObjBufferForObjAndAfter(objIndex: Obj) void;

extern fn objMapStringEncodeExt(idx: Obj) usize;
extern fn objMapLenExt(idx: Obj) usize;
extern fn readObjMapBytesExt(idx: Obj, begin: [*]u8) void;

extern fn postMessage(tagIdx: Obj, id: Obj) void;
extern fn exitExt(objIndex: Obj) noreturn;

pub fn slice(obj: Obj, data: anytype) Obj {
    const T = std.meta.Elem(@TypeOf(data));

    return bytesExt(obj, data.ptr, data.len * @sizeOf(T));
}

pub fn string(a: []const u8) Obj {
    return bytesExt(.String, a.ptr, a.len);
}

pub fn readBytesObj(obj: Obj, alloc: Allocator) ![]u8 {
    if (builtin.target.cpu.arch != .wasm32) return &.{};
    const len = objMapLenExt(obj);
    const data = try alloc.alloc(u8, len);

    readObjMapBytesExt(obj, data.ptr);

    return data;
}

pub fn readStringObj(obj: Obj, alloc: Allocator) ![]u8 {
    if (builtin.target.cpu.arch != .wasm32) return &.{};
    const len = objMapStringEncodeExt(obj);
    const data = try alloc.alloc(u8, len);

    readObjMapBytesExt(obj, data.ptr);

    return data;
}

pub fn exitFmt(comptime fmt: []const u8, args: anytype) noreturn {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();

    const allocResult = std.fmt.allocPrint(temp, fmt, args);
    const s = allocResult catch @panic("failed to print");

    exit(s);
}

pub fn exit(msg: []const u8) noreturn {
    const obj = bytesExt(.String, msg.ptr, msg.len);
    return exitExt(obj);
}

pub fn stringFmtObj(comptime fmt: []const u8, args: anytype) Obj {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const allocResult = std.fmt.allocPrint(temp, fmt, args);
    const out = allocResult catch @panic("failed to print");

    return bytesExt(.String, out.ptr, out.len);
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

    postFmt(level_obj, fmt ++ "\n", args);
}

pub fn postFmt(level: Obj, comptime fmt: []const u8, args: anytype) void {
    if (builtin.target.cpu.arch == .wasm32) {
        const obj = stringFmtObj(fmt, args);
        postMessage(level, obj);

        clearObjBufferForObjAndAfter(obj);
    } else {
        std.log.info(fmt, args);
    }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    @setCold(true);

    if (builtin.target.cpu.arch != .wasm32) {
        std.builtin.default_panic(msg, error_return_trace);
    }

    _ = error_return_trace;

    exit(msg);
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
