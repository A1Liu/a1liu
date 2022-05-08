const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;

const Vec2 = @Vector(2, f32);

const ext = struct {
    extern fn setTriangles(obj: wasm.Obj) void;

    fn onClickExt(posX: f32, posY: f32, width: f32, height: f32) callconv(.C) void {
        onClick(posX, posY, width, height) catch @panic("onClick failed");
    }

    fn printExt(msg: wasm.Obj) callconv(.C) void {
        print(msg) catch @panic("print failed");
    }

    fn initExt() callconv(.C) void {
        init() catch @panic("init failed");
    }
};

comptime {
    @export(ext.onClickExt, .{ .name = "onClick", .linkage = .Strong });
    @export(ext.printExt, .{ .name = "print", .linkage = .Strong });
    @export(ext.initExt, .{ .name = "init", .linkage = .Strong });
}

// First 36 triangles are reserved for the lines created during triangle drawing
var triangles: ArrayList(f32) = undefined;
var temp_triangle: std.BoundedArray(f32, 6) = undefined;
var temp_begin: usize = 0;

fn translatePos(posX: f32, posY: f32, dims: Vec2) Vec2 {
    return .{ posX * 2 / dims[0] - 1, -(posY * 2 / dims[1] - 1) };
}

export fn onRightClick() void {
    triangles.items.len = temp_begin;
    temp_triangle.len = 0;

    const obj = wasm.out.slice(triangles.items);
    ext.setTriangles(obj);
}

export fn onMove(posX: f32, posY: f32, width: f32, height: f32) void {
    if (temp_triangle.len < 2) return;

    const dims: Vec2 = .{ width, height };
    const pos = translatePos(posX, posY, dims);

    const len = temp_triangle.len;
    temp_triangle.slice()[(len - 2)..][0..2].* = pos;

    if (temp_triangle.len < 4) return;

    const prev: Vec2 = temp_triangle.slice()[(len - 4)..][0..2].*;

    const vector = pos - prev;
    const rot90: Vec2 = .{ -vector[1], vector[0] };

    const tangent_len = @sqrt(rot90[0] * rot90[0] + rot90[1] * rot90[1]);
    const tangent = rot90 * @splat(2, 2 / tangent_len) / dims;

    const data_begin = temp_begin + ((len - 4) / 2 * 12);
    const data = triangles.items[data_begin..];

    // first triangle, drawn clockwise
    data[0..2].* = prev + tangent;
    data[2..4].* = pos + tangent;
    data[4..6].* = prev - tangent;

    // second triangle, drawn clockwise
    data[6..8].* = prev - tangent;
    data[8..10].* = pos + tangent;
    data[10..12].* = pos - tangent;

    const obj = wasm.out.slice(triangles.items);
    ext.setTriangles(obj);
}

fn onClick(posX: f32, posY: f32, width: f32, height: f32) !void {
    const pos = translatePos(posX, posY, .{ width, height });

    if (temp_triangle.len == temp_triangle.buffer.len) {
        triangles.items.len = temp_begin;
        try triangles.appendSlice(temp_triangle.slice());
        temp_begin = triangles.items.len;
        temp_triangle.len = 0;

        const obj = wasm.out.slice(triangles.items);
        ext.setTriangles(obj);

        wasm.out.post(.success, "new triangle!", .{});

        return;
    }

    if (temp_triangle.len == 0) {
        temp_triangle.buffer[0..2].* = pos;
        temp_triangle.len += 2;
    }

    const len = temp_triangle.len;
    temp_triangle.buffer[len..][0..2].* = pos;
    temp_triangle.len += 2;

    try triangles.appendSlice(&.{
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
    });
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
    temp_triangle = try std.BoundedArray(f32, 6).init(0);
    triangles = ArrayList(f32).init(liu.Pages);

    // try triangles.appendSlice(&.{
    //     0, 0, 0, 0, 0, 0,
    //     0, 0, 0, 0, 0, 0,

    //     0, 0, 0, 0, 0, 0,
    //     0, 0, 0, 0, 0, 0,

    //     0, 0, 0, 0, 0, 0,
    //     0, 0, 0, 0, 0, 0,
    // });

    std.log.info("WASM initialized!", .{});
}
