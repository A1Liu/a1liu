const std = @import("std");
const liu = @import("liu");

const input = @import("./input.zig");
const rows = input.rows;
const keys = input.keys;

// https://youtu.be/SFKR5rZBu-8?t=2202

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const Vec2 = liu.Vec2;
pub const BBox = struct {
    pos: Vec2,
    width: f32,
    height: f32,
};

const ext = struct {
    extern fn fillStyle(r: f32, g: f32, b: f32) void;
    extern fn fillRect(x: i32, y: i32, width: i32, height: i32) void;
    extern fn setFont(font: wasm.Obj) void;
    extern fn fillText(text: wasm.Obj, x: i32, y: i32) void;
};

const Camera = struct {
    bbox: BBox = .{
        .pos = Vec2{ 0, 0 },
        .height = 10,
        .width = 10,
    },
    world_to_pixel: f32 = 1,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn setDims(self: *Self, pix_width: u32, pix_height: u32) void {
        self.world_to_pixel = @intToFloat(f32, pix_height) / self.bbox.height;
        self.bbox.width = @intToFloat(f32, pix_width) / self.world_to_pixel;
    }

    pub fn screenSpaceCoordinates(self: *const Self, pos: Vec2) Vec2 {
        const pos_camera = pos - self.bbox.pos;

        const pos_canvas = Vec2{
            pos_camera[0] * self.world_to_pixel,
            (self.bbox.height - pos_camera[1]) * self.world_to_pixel,
        };

        return pos_canvas;
    }

    pub fn getScreenBoundingBox(self: *const Self, bbox: BBox) BBox {
        const coords = self.screenSpaceCoordinates(bbox.pos);
        const screen_height = bbox.height * self.world_to_pixel;

        return BBox{
            .pos = Vec2{ coords[0], coords[1] - screen_height },
            .width = bbox.width * self.world_to_pixel,
            .height = screen_height,
        };
    }
};

const RenderC = struct {};

const PositionC = struct {
    pos: Vec2,
};

const MoveC = struct {
    direction: Vec2, // normalized
    speed: f32,
};

const DecisionC = union(enum) {
    player: void,
};

export fn setDims(posX: u32, posY: u32) void {
    camera.setDims(posX, posY);
}

export fn init(timestamp: f64) void {
    wasm.initIfNecessary();

    initErr(timestamp) catch @panic("meh");

    wasm.post(.info, "WASM initialized!", .{});
}

const Registry = liu.ecs.Registry(&.{MoveC});

fn initErr(timestamp: f64) !void {
    previous_time = timestamp;
    large_font = wasm.make.fmt(.manual, "bold 48px sans-serif", .{});
    small_font = wasm.make.fmt(.manual, "10px sans-serif", .{});

    registry = try Registry.init(16, liu.Pages);
}

var previous_time: f64 = undefined;
var large_font: wasm.Obj = undefined;
var small_font: wasm.Obj = undefined;
pub var registry: Registry = undefined;

pub var camera: Camera = .{};
var ground_bbox: BBox = BBox{
    .pos = Vec2{ 0, 0 },
    .width = 1,
    .height = 1,
};
var block_bbox: BBox = BBox{
    .pos = Vec2{ 5, 1 },
    .width = 1,
    .height = 1,
};
var is_airborne: bool = false;
var velocity: Vec2 = Vec2{ 0, 0 };

export fn run(timestamp: f64) void {
    const delta = @floatCast(f32, timestamp - previous_time);
    defer previous_time = timestamp;

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    defer input.frameCleanup();

    // Input
    if (keys[10].pressed) {
        velocity[0] -= 8;
        // wasm.post(.info, "Hello!\n", .{});
    }

    if (keys[11].pressed) {
        velocity[1] -= 8;
        // wasm.post(.info, "Hello!\n", .{});
    }

    if (keys[12].pressed) {
        velocity[0] += 8;
        // wasm.post(.info, "Hello!\n", .{});
    }

    if (keys[1].pressed) {
        // block_bbox.pos[1] += 0.25;
        velocity[1] += 8;
        is_airborne = true;
        // wasm.post(.info, "Hello {d:.2},{d:.2} {d:.1}x{d:.1}!\n", .{
        //     block_screen_bbox.pos[0],
        //     block_screen_bbox.pos[1],
        //     block_screen_bbox.width,
        //     block_screen_bbox.height,
        // });
    }

    // Gameplay
    // applies a friction force when mario hits the ground.
    block_bbox.pos += velocity * @splat(2, delta / 1000);

    // const y = velocity[1];
    // if ((y * y) > 1) {
    //     wasm.post(.info, "{d:.2} {}", .{ y, delta });
    // }

    // gravity
    velocity[1] -= 0.014 * delta;

    if (!is_airborne and velocity[0] != 0) {
        // Friction is applied in the opposite direction of velocity
        // You cannot gain speed in the opposite direction from friction
        const friction: f32 = 0.05 * delta;
        if (velocity[0] > 0) {
            velocity[0] = std.math.clamp(velocity[0] - friction, 0, std.math.inf(f32));
        } else {
            velocity[0] = std.math.clamp(velocity[0] + friction, -std.math.inf(f32), 0);
        }
    }

    const groundY: f32 = ground_bbox.pos[1] + ground_bbox.height;

    if (block_bbox.pos[1] < groundY) {
        if (is_airborne) {
            is_airborne = false;
        }

        block_bbox.pos[1] = groundY;
        velocity[1] = 0;
    }

    // Rendering
    ext.fillStyle(0.2, 0.5, 0.3);
    ground_bbox.width = camera.bbox.width;

    const ground_screen_bbox = camera.getScreenBoundingBox(ground_bbox);
    ext.fillRect(
        @floatToInt(i32, ground_screen_bbox.pos[0]),
        @floatToInt(i32, ground_screen_bbox.pos[1]),
        @floatToInt(i32, ground_screen_bbox.width),
        @floatToInt(i32, ground_screen_bbox.height),
    );

    ext.fillStyle(0.6, 0.5, 0.4);

    const block_screen_bbox = camera.getScreenBoundingBox(block_bbox);
    ext.fillRect(
        @floatToInt(i32, block_screen_bbox.pos[0]),
        @floatToInt(i32, block_screen_bbox.pos[1]),
        @floatToInt(i32, block_screen_bbox.width),
        @floatToInt(i32, block_screen_bbox.height),
    );

    // USER INTERFACE
    ext.fillStyle(0.5, 0.5, 0.5);

    ext.setFont(large_font);

    const fps_message = wasm.out.fmt("FPS: {d:.2}", .{1000 / delta});
    ext.fillText(fps_message, 5, 160);

    ext.setFont(small_font);

    var begin: u32 = 0;
    var topY: i32 = 5;

    for (rows) |row| {
        var leftX = row.leftX;
        const end = row.end;

        for (keys[begin..row.end]) |key| {
            const color: f32 = if (key.down) 0.3 else 0.5;
            ext.fillStyle(color, color, color);

            ext.fillRect(leftX, topY, 30, 30);

            ext.fillStyle(1, 1, 1);
            const s = &[_]u8{@truncate(u8, key.code)};
            const letter = wasm.out.fmt("{s}", .{s});
            ext.fillText(letter, leftX + 15, topY + 10);

            leftX += 35;
        }

        topY += 35;

        begin = end;
    }
}
