const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;

const ext = struct {
    fn printExt(msg: wasm.Obj) callconv(.C) void {
        print(msg) catch @panic("print failed");
    }

    fn initExt() callconv(.C) void {
        init() catch @panic("init failed");
    }
};

// I think this needs to be in root. I tried moving it inside `ext` and most of
// the code got deleted.
comptime {
    @export(ext.printExt, .{ .name = "print", .linkage = .Strong });
    @export(ext.initExt, .{ .name = "init", .linkage = .Strong });
}

pub fn print(msg: wasm.Obj) !void {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const message = try wasm.readStringObj(msg, temp);
    wasm.postFmt(.info, "{s}!", .{message});
}

pub fn init() !void {
    wasm.initIfNecessary();

    std.log.info("WASM initialized!", .{});
}
