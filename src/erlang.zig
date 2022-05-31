const std = @import("std");
const liu = @import("liu");

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

const TransformC = struct {
    position: Vec2,
    scale: f32,
};

const PhysicsC = struct {};

const MoveC = struct {
    direction: Vec2, // normalized
    speed: f32,
};

const DecisionC = union(enum) {
    player: void,
    walk: f32,
};

export fn setDims(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onRightClick(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onKey(code: u32) void {
    _ = code;
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

fn initErr() !void {
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
