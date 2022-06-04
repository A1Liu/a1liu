const std = @import("std");
const liu = @import("liu");

// https://youtu.be/SFKR5rZBu-8?t=2202

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const Vec2 = liu.Vec2;
const Vec3 = liu.Vec3;
const Point = struct { pos: Vec2, color: Vec3 };

const ext = struct {
    extern fn renderExt(triangles: wasm.Obj, colors: wasm.Obj) void;
};

var render: Render = .{};
const Render = struct {
    const List = std.ArrayListUnmanaged;
    const Self = @This();

    const TRIANGLE_SIZE: u32 = 12;

    dims: Vec2 = Vec2{ 0, 0 },
    triangles: List(f32) = .{},
    colors: List(f32) = .{},

    pub fn render(self: *Self) void {
        const mark = wasm.watermark();
        defer wasm.setWatermark(mark);

        const obj = wasm.out.slice(self.triangles.items);
        const obj2 = wasm.out.slice(self.colors.items);
        ext.renderExt(obj, obj2);
    }
};

const LocationC = struct {
    bb0: Vec2,
    bb1: Vec2,
};

const CollisionClass = struct {};

const MoveC = struct {
    direction: Vec2, // normalized
    speed: f32,
};

const DecisionC = union(enum) {
    player: void,
    walk: f32,
    jumper: f32,
};

const HealthC = struct {
    health: f32,
};

const FlammableC = struct {
    damage: f32,
    timeSinceLastDamage: f32,
    rate: f32,
};

export fn setDims(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onRightClick(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onKey(down: bool, code: u32) void {
    for (keys) |*key, idx| {
        if (code == key.code) {
            key.pressed = down;

            const color: f32 = if (down) 0.3 else 0.5;
            std.mem.set(f32, render.colors.items[(idx * 18)..][0..18], color);

            render.render();
            return;
        }
    }
}

export fn onMove(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onClick(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn init() void {
    wasm.initIfNecessary();

    initErr() catch @panic("meh");

    wasm.out.post(.info, "WASM initialized!", .{});
}

export fn initialRender() void {
    render.render();
}

fn addBox(p0: Vec2, p2: Vec2) !void {
    var verts: [12]f32 = undefined;

    const p1 = Vec2{ p0[0], p2[1] };
    const p3 = Vec2{ p2[0], p0[1] };

    verts[0..2].* = p0;
    verts[2..4].* = p1;
    verts[4..6].* = p2;
    verts[6..8].* = p0;
    verts[8..10].* = p2;
    verts[10..12].* = p3;

    var colors: [18]f32 = undefined;

    var i: u32 = 0;
    while (i < colors.len) : (i += 3) {
        colors[i] = 0.5;
        colors[i + 1] = 0.5;
        colors[i + 2] = 0.5;
    }

    try render.triangles.appendSlice(liu.Pages, &verts);
    try render.colors.appendSlice(liu.Pages, &colors);
}

const KeyBox = struct {
    code: u32,
    pressed: bool = false,
};

const KeyRow = struct {
    end: u32,
    leftX: f32,
};

const rows: [3]KeyRow = .{
    .{ .end = 10, .leftX = -0.99 },
    .{ .end = 19, .leftX = -0.98 },
    .{ .end = 26, .leftX = -0.96 },
};

var keys: [26]KeyBox = [_]KeyBox{
    .{ .code = 'Q' },
    .{ .code = 'W' },
    .{ .code = 'E' },
    .{ .code = 'R' },
    .{ .code = 'T' },
    .{ .code = 'Y' },
    .{ .code = 'U' },
    .{ .code = 'I' },
    .{ .code = 'O' },
    .{ .code = 'P' },

    .{ .code = 'A' },
    .{ .code = 'S' },
    .{ .code = 'D' },
    .{ .code = 'F' },
    .{ .code = 'G' },
    .{ .code = 'H' },
    .{ .code = 'J' },
    .{ .code = 'K' },
    .{ .code = 'L' },

    .{ .code = 'Z' },
    .{ .code = 'X' },
    .{ .code = 'C' },
    .{ .code = 'V' },
    .{ .code = 'B' },
    .{ .code = 'N' },
    .{ .code = 'M' },
};

fn initErr() !void {
    var topY: f32 = 0.95;

    var begin: u32 = 0;
    for (rows) |row| {
        var leftX = row.leftX;
        const end = row.end;

        for (keys[begin..row.end]) |key| {
            _ = key;

            try addBox(Vec2{ leftX, topY }, Vec2{ leftX + 0.05, topY - 0.1 });
            leftX += 0.06;
        }

        topY -= 0.12;

        begin = end;
    }

    try render.triangles.appendSlice(liu.Pages, &.{
        -0.5, -0.5,
        0,    0.5,
        0.5,  -0.5,
    });

    try render.colors.appendSlice(liu.Pages, &.{
        1, 0, 0,
        0, 1, 0,
        0, 0, 1,
    });
}
