const std = @import("std");
const root = @import("root");
const liu = @import("./lib.zig");

const ArrayList = std.ArrayList;
const builtin = std.builtin;

pub const Obj = u32;

extern fn stringObjExt(message: [*]const u8, length: usize) Obj;
pub extern fn pushCopy(idx: u32) u32;

pub extern fn clearObjBufferForObjAndAfter(objIndex: Obj) void;
pub extern fn clearObjBuffer() void;

pub extern fn logObj(id: Obj) void;

pub extern fn exitExt(objIndex: Obj) noreturn;

pub fn exitFmt(comptime fmt: []const u8, args: anytype) noreturn {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();

    const allocResult = std.fmt.allocPrint(temp, fmt, args);
    const s = allocResult catch @panic("failed to print");

    exit(s);
}

pub fn exit(bytes: []const u8) noreturn {
    const obj = stringObjExt(bytes.ptr, bytes.len);
    return exitExt(obj);
}

pub fn stringObj(bytes: []const u8) Obj {
    return stringObjExt(bytes.ptr, bytes.len);
}

pub fn stringFmtObj(comptime fmt: []const u8, args: anytype) Obj {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const allocResult = std.fmt.allocPrint(temp, fmt, args);
    const bytes = allocResult catch @panic("failed to print");

    return stringObjExt(bytes.ptr, bytes.len);
}

pub const strip_debug_info = true;
pub const have_error_return_tracing = false;

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime input_format: []const u8,
    args: anytype,
) void {
    if (@enumToInt(message_level) > @enumToInt(std.log.level)) {
        return;
    }

    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const prefix = comptime prefix: {
        const prefix = "[" ++ message_level.asText() ++ "]: ";

        if (scope == .default) {
            break :prefix prefix;
        } else {
            break :prefix @tagName(scope) ++ prefix;
        }
    };

    const fmt = prefix ++ input_format ++ "\n";

    const allocResult = std.fmt.allocPrint(temp, fmt, args);
    const s = allocResult catch @panic("failed to print");

    const obj = stringObjExt(s.ptr, s.len);
    logObj(obj);

    clearObjBufferForObjAndAfter(obj);
}

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);

    _ = error_return_trace;

    exit(msg);
}

const CommandBuffer = liu.RingBuffer(root.WasmCommand, 64);
var initialized: bool = false;

var cmd_bump: liu.Bump = undefined;
var commands: CommandBuffer = undefined;

const CmdAlloc = cmd_bump.allocator();

pub fn initIfNecessary() void {
    if (!initialized) {
        cmd_bump = liu.Bump.init(4096, liu.Pages);
        commands = CommandBuffer.init();

        initialized = true;
    }
}

export fn commandArrayAllocate(len: u32) [*c]u8 {
    initIfNecessary();

    if (CmdAlloc.alloc(u8, len)) |range| {
        return range.ptr;
    } else |_| {
        return null;
    }
}
