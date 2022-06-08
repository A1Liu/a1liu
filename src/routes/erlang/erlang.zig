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
const Vec3 = liu.Vec3;
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

const RenderC = struct {
    color: Vec3,
    sprite_width: f32,
    sprite_height: f32,
};

const PositionC = struct {
    pos: Vec2,
};

const CollisionC = struct {
    width: f32,
    height: f32,
};

const MoveC = struct {
    velocity: Vec2,
    is_airborne: bool = false,
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

const Registry = liu.ecs.Registry(&.{
    PositionC,
    MoveC,
    RenderC,
    DecisionC,
    CollisionC,
});

fn initErr(timestamp: f64) !void {
    previous_time = timestamp;
    large_font = wasm.make.fmt(.manual, "bold 48px sans-serif", .{});
    small_font = wasm.make.fmt(.manual, "10px sans-serif", .{});

    registry = try Registry.init(16, liu.Pages);

    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        const box = try registry.create("box");
        _ = try registry.addComponent(box, PositionC{
            .pos = Vec2{ @intToFloat(f32, i) + 5, 1 },
        });
        _ = try registry.addComponent(box, RenderC{
            .color = Vec3{ 0.6, 0.5, 0.4 },
            .sprite_width = 0.5,
            .sprite_height = 0.5,
        });
        _ = try registry.addComponent(box, CollisionC{
            .width = 0.5,
            .height = 0.5,
        });
        _ = try registry.addComponent(box, MoveC{
            .velocity = Vec2{ 0, 0 },
        });
        _ = try registry.addComponent(box, DecisionC{ .player = {} });
    }

    const ground = try registry.create("ground");
    _ = try registry.addComponent(ground, PositionC{
        .pos = Vec2{ 0, 0 },
    });
    _ = try registry.addComponent(ground, RenderC{
        .color = Vec3{ 0.2, 0.5, 0.3 },
        .sprite_width = 100,
        .sprite_height = 1,
    });
}

var previous_time: f64 = undefined;
var large_font: wasm.Obj = undefined;
var small_font: wasm.Obj = undefined;
pub var registry: Registry = undefined;

pub var camera: Camera = .{};

export fn run(timestamp: f64) void {
    defer input.frameCleanup();

    const delta = @floatCast(f32, timestamp - previous_time);
    defer previous_time = timestamp;

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    // Input
    {
        var view = registry.view(struct {
            move_c: *MoveC,
            decide_c: DecisionC,
        });

        while (view.next()) |elem| {
            const move_c = elem.move_c;
            const decide_c = elem.decide_c;

            if (decide_c != .player) continue;

            if (keys[10].pressed) {
                move_c.velocity[0] -= 8;
            }

            if (keys[11].pressed) {
                move_c.velocity[1] -= 8;
            }

            if (keys[12].pressed) {
                move_c.velocity[0] += 8;
            }

            if (keys[1].pressed) {
                move_c.velocity[1] += 8;
                move_c.is_airborne = true;
            }
        }
    }

    // Gameplay

    {
        var view = registry.view(struct {
            pos_c: *PositionC,
            move_c: *MoveC,
            collision_c: CollisionC,
        });

        const groundY: f32 = 1;
        while (view.next()) |elem| {
            const pos_c = elem.pos_c;
            const move_c = elem.move_c;
            const collision_c = elem.collision_c;

            pos_c.pos += move_c.velocity * @splat(2, delta / 1000); // move the thing
            if (pos_c.pos[1] < groundY) {
                if (move_c.is_airborne) {
                    move_c.is_airborne = false;
                }

                pos_c.pos[1] = groundY;
                move_c.velocity[1] = 0;
            }

            const cam_pos0 = camera.bbox.pos;
            const cam_dims = Vec2{ camera.bbox.width, camera.bbox.height };
            const cam_pos1 = cam_pos0 + cam_dims;
            if (pos_c.pos[0] < cam_pos0[0]) {
                pos_c.pos[0] = cam_pos0[0];
                move_c.velocity[0] = 0;
            }

            if (pos_c.pos[0] + collision_c.width > cam_pos1[0]) {
                pos_c.pos[0] = cam_pos1[0] - collision_c.width;
                move_c.velocity[0] = 0;
            }

            if (pos_c.pos[1] < cam_pos0[1]) {
                pos_c.pos[1] = cam_pos0[1];
                move_c.velocity[1] = 0;
            }

            if (pos_c.pos[1] + collision_c.height > cam_pos1[1]) {
                pos_c.pos[1] = cam_pos1[1] - collision_c.width;
                move_c.velocity[1] = 0;
            }
        }
    }

    {
        var view = registry.view(struct {
            move_c: *MoveC,
        });

        while (view.next()) |elem| {
            const move = elem.move_c;

            // apply gravity
            move.velocity[1] -= 0.014 * delta;

            // applies a friction force when mario hits the ground.
            if (!move.is_airborne and move.velocity[0] != 0) {
                // Friction is applied in the opposite direction of velocity
                // You cannot gain speed in the opposite direction from friction
                const friction: f32 = 0.05 * delta;
                if (move.velocity[0] > 0) {
                    move.velocity[0] = std.math.clamp(
                        move.velocity[0] - friction,
                        0,
                        std.math.inf(f32),
                    );
                } else {
                    move.velocity[0] = std.math.clamp(
                        move.velocity[0] + friction,
                        -std.math.inf(f32),
                        0,
                    );
                }
            }
        }
    }

    // Rendering
    {
        var view = registry.view(struct {
            pos_c: *PositionC,
            render: *const RenderC,
        });

        while (view.next()) |elem| {
            const pos_c = elem.pos_c;
            const render = elem.render;

            const color = render.color;
            ext.fillStyle(color[0], color[1], color[2]);
            const bbox = camera.getScreenBoundingBox(BBox{
                .pos = pos_c.pos,
                .width = render.sprite_width,
                .height = render.sprite_height,
            });

            ext.fillRect(
                @floatToInt(i32, bbox.pos[0]),
                @floatToInt(i32, bbox.pos[1]),
                @floatToInt(i32, bbox.width),
                @floatToInt(i32, bbox.height),
            );
        }
    }

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
