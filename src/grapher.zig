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

// Something to make simple graphs for memes

comptime {
    @export(ext.onClickExt, .{ .name = "onClick", .linkage = .Strong });
    @export(ext.printExt, .{ .name = "print", .linkage = .Strong });
    @export(ext.initExt, .{ .name = "init", .linkage = .Strong });
}

// First 36 triangles are reserved for the lines created during triangle drawing
var triangles: ArrayList(f32) = undefined;
var temp_triangles: std.BoundedArray(f32, 6) = undefined;

export fn onMove(posX_: f32, posY_: f32, width: f32, height: f32) void {
    if (temp_triangles.len < 2) return;

    const posX = posX_ * 2 / width - 1;
    const posY = -(posY_ * 2 / height - 1);
    const dims: Vec2 = .{ width, height };

    const len = temp_triangles.len;
    temp_triangles.slice()[len - 2] = posX;
    temp_triangles.slice()[len - 1] = posY;

    if (temp_triangles.len < 4) return;

    const prevX = temp_triangles.slice()[len - 4];
    const prevY = temp_triangles.slice()[len - 3];

    const pos: Vec2 = .{ posX, posY };
    const prev: Vec2 = .{ prevX, prevY };

    const vector = pos - prev;
    const rotated: Vec2 = .{ -vector[1], vector[0] };

    const tangent_len = std.math.sqrt(rotated[0] * rotated[0] + rotated[1] * rotated[1]);
    const tangent = rotated * @splat(2, 2 / tangent_len) / dims;

    const line_block_begin = (len - 4) / 2 * 12;
    const data = triangles.items[line_block_begin..];

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

fn onClick(posX_: f32, posY_: f32, width: f32, height: f32) !void {
    const posX = posX_ * 2 / width - 1;
    const posY = -(posY_ * 2 / height - 1);

    if (temp_triangles.len == temp_triangles.buffer.len) {
        try triangles.ensureUnusedCapacity(6);
        try triangles.appendSlice(temp_triangles.slice());

        temp_triangles.len = 0;
        const items = triangles.items;
        std.mem.set(f32, items[0..36], 0);
        const obj = wasm.out.slice(triangles.items);
        ext.setTriangles(obj);

        wasm.out.post(.success, "new triangle!", .{});
        return;
    }

    if (temp_triangles.len == 0) {
        try temp_triangles.append(posX);
        try temp_triangles.append(posY);
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
    temp_triangles = try std.BoundedArray(f32, 6).init(0);
    triangles = ArrayList(f32).init(liu.Pages);

    try triangles.appendSlice(&.{
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,

        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
    });

    std.log.info("WASM initialized!", .{});
}
