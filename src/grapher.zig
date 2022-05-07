const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;

const ext = struct {
    extern fn setTriangles(obj: wasm.Obj) void;

    fn onClickExt(posX: f32, posY: f32) callconv(.C) void {
        onClick(posX, posY) catch @panic("onClick failed");
    }

    fn printExt(msg: wasm.Obj) callconv(.C) void {
        print(msg) catch @panic("print failed");
    }

    fn initExt() callconv(.C) void {
        init() catch @panic("init failed");
    }
};

// Something to make simple graphs for memes

comptime {
    @export(ext.onClickExt, .{ .name = "onClick", .linkage = .Strong });
    @export(ext.printExt, .{ .name = "print", .linkage = .Strong });
    @export(ext.initExt, .{ .name = "init", .linkage = .Strong });
}

var triangles: ArrayList(f32) = undefined;
var temp_triangles: std.BoundedArray(f32, 4) = undefined;

fn onClick(posX: f32, posY: f32) !void {
    wasm.out.post(.success, "pos: {},{}", .{ posX, posY });

    if (temp_triangles.len == temp_triangles.buffer.len) {
        try triangles.ensureUnusedCapacity(6);
        try triangles.appendSlice(temp_triangles.slice());
        try triangles.append(posX);
        try triangles.append(posY);

        temp_triangles.len = 0;

        const obj = wasm.out.slice(triangles.items);
        ext.setTriangles(obj);
        return;
    }

    try temp_triangles.append(posX);
    try temp_triangles.append(posY);
}

pub fn print(msg: wasm.Obj) !void {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const message = try wasm.in.string(msg, temp);
    wasm.out.post(.info, "{s}!", .{message});

    const obj = wasm.out.slice(triangles.items);
    ext.setTriangles(obj);
}

pub fn init() !void {
    wasm.initIfNecessary();
    temp_triangles = try std.BoundedArray(f32, 4).init(0);
    triangles = ArrayList(f32).init(liu.Pages);

    std.log.info("WASM initialized!", .{});
}
