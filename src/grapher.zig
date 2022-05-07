const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;

const ext = struct {
    extern fn setTriangles(obj: wasm.Obj) void;

    fn printExt(msg: wasm.Obj) callconv(.C) void {
        print(msg) catch @panic("print failed");
    }

    fn initExt() callconv(.C) void {
        init() catch @panic("init failed");
    }
};

// Something to make simple graphs for memes

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

    const message = try wasm.in.string(msg, temp);
    wasm.out.post(.info, "{s}!", .{message});

    const a = [_]f32{ 0, 0, 0, 0.5, 0.7, 0 };
    const obj = wasm.out.slice(&a);
    ext.setTriangles(obj);
}

pub fn init() !void {
    wasm.initIfNecessary();

    std.log.info("WASM initialized!", .{});
}
