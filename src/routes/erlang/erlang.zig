const std = @import("std");
const liu = @import("liu");

const input = @import("./input.zig");
const rows = input.rows;
const keys = input.keys;

// https://youtu.be/SFKR5rZBu-8?t=2202
// https://stackoverflow.com/questions/22511158/how-to-profile-web-workers-in-chrome

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const Vec2 = liu.Vec2;
const Vec3 = liu.Vec3;
pub const BBox = struct {
    pos: Vec2,
    width: f32,
    height: f32,

    const Overlap = struct {
        result: bool,
        x: bool,
        y: bool,
    };

    pub fn overlap(self: @This(), other: @This()) Overlap {
        const pos1 = self.pos + Vec2{ self.width, self.height };
        const other_pos1 = other.pos + Vec2{ other.width, other.height };
        const x = self.pos[0] < other_pos1[0] and other.pos[0] < pos1[0];
        const y = self.pos[1] < other_pos1[1] and other.pos[1] < pos1[1];

        return .{
            .result = x and y,
            .y = y,
            .x = x,
        };
    }
};

const ext = struct {
    extern fn fillStyle(r: f32, g: f32, b: f32) void;
    extern fn fillRect(x: i32, y: i32, width: i32, height: i32) void;
    extern fn setFont(font: wasm.Obj) void;
    extern fn fillText(text: wasm.Obj, x: i32, y: i32) void;
};

const Camera = struct {
    pos: Vec2 = Vec2{ 0, 0 },
    height: f32 = 30,
    width: f32 = 10,
    world_to_pixel: f32 = 1,

    const Self = @This();

    pub fn init() Self {
        return .{};
    }

    pub fn setDims(self: *Self, pix_width: u32, pix_height: u32) void {
        self.world_to_pixel = @intToFloat(f32, pix_height) / self.height;
        self.width = @intToFloat(f32, pix_width) / self.world_to_pixel;
    }

    pub fn screenSpaceCoordinates(self: *const Self, pos: Vec2) Vec2 {
        const pos_camera = pos - self.pos;

        const pos_canvas = Vec2{
            pos_camera[0] * self.world_to_pixel,
            (self.height - pos_camera[1]) * self.world_to_pixel,
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

const norm_color: Vec3 = Vec3{ 0.6, 0.5, 0.4 };

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
};

const ForceC = struct {
    accel: Vec2,
    friction: f32,
    is_airborne: bool = false,
};

const DecisionC = union(enum) {
    player: void,
};

export fn setDims(posX: u32, posY: u32) void {
    camera.setDims(posX, posY);
}

export fn init() void {
    wasm.initIfNecessary();

    initErr() catch @panic("meh");

    wasm.post(.info, "WASM initialized!", .{});
}

const Registry = liu.ecs.Registry(&.{
    PositionC,
    MoveC,
    RenderC,
    DecisionC,
    CollisionC,
    ForceC,
});

fn initErr() !void {
    large_font = wasm.make.fmt(.manual, "bold 48px sans-serif", .{});
    small_font = wasm.make.fmt(.manual, "10px sans-serif", .{});

    registry = try Registry.init(16, liu.Pages);

    var i: u32 = 0;
    while (i < 3) : (i += 1) {
        const box = try registry.create("box");
        try registry.addComponent(box, PositionC{
            .pos = Vec2{ @intToFloat(f32, i) + 5, 3 },
        });
        try registry.addComponent(box, RenderC{
            .color = norm_color,
            .sprite_width = 0.5,
            .sprite_height = 3,
        });
        try registry.addComponent(box, CollisionC{
            .width = 0.5,
            .height = 3,
        });
        try registry.addComponent(box, MoveC{
            .velocity = Vec2{ 0, 0 },
        });
        try registry.addComponent(box, DecisionC{ .player = {} });

        try registry.addComponent(box, ForceC{
            .accel = Vec2{ 0, -14 },
            .friction = 0.05,
        });
    }

    const bump = try registry.create("bump");
    try registry.addComponent(bump, PositionC{
        .pos = Vec2{ 10, 4 },
    });
    try registry.addComponent(bump, CollisionC{
        .width = 1,
        .height = 1,
    });
    try registry.addComponent(bump, RenderC{
        .color = Vec3{ 0.1, 0.5, 0.3 },
        .sprite_width = 1,
        .sprite_height = 1,
    });

    const ground = try registry.create("ground");
    try registry.addComponent(ground, PositionC{
        .pos = Vec2{ 0, 0 },
    });
    try registry.addComponent(ground, CollisionC{
        .width = 100,
        .height = 1,
    });
    try registry.addComponent(ground, RenderC{
        .color = Vec3{ 0.2, 0.5, 0.3 },
        .sprite_width = 100,
        .sprite_height = 1,
    });
}

var frame_id: u64 = 0;
var start_time: f64 = undefined;
var previous_time: f64 = undefined;
var large_font: wasm.Obj = undefined;
var small_font: wasm.Obj = undefined;
pub var registry: Registry = undefined;

pub var camera: Camera = .{};

export fn setInitialTime(timestamp: f64) void {
    start_time = timestamp;
    previous_time = timestamp;
}

export fn run(timestamp: f64) void {
    defer input.frameCleanup();
    defer frame_id += 1;
    defer previous_time = timestamp;

    if (timestamp - start_time < 300) {
        return;
    }

    const delta = @floatCast(f32, timestamp - previous_time);

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    // Input
    {
        var view = registry.view(struct {
            move_c: *MoveC,
            decide_c: DecisionC,
            force_c: ForceC,
        });

        while (view.next()) |elem| {
            const move_c = elem.move_c;

            if (elem.decide_c != .player) continue;

            if (keys[11].pressed) {
                move_c.velocity[1] -= 8;
            }

            if (keys[1].pressed) {
                move_c.velocity[1] += 8;
            }

            if (elem.force_c.is_airborne) {
                if (keys[10].pressed) {
                    move_c.velocity[0] -= 8;
                }

                if (keys[12].pressed) {
                    move_c.velocity[0] += 8;
                }
            } else {
                if (keys[10].down) {
                    move_c.velocity[0] -= 8;
                    move_c.velocity[0] = std.math.clamp(move_c.velocity[0], -8, 0);
                }

                if (keys[12].down) {
                    move_c.velocity[0] += 8;
                    move_c.velocity[0] = std.math.clamp(move_c.velocity[0], 0, 8);
                }
            }
        }
    }

    // Gameplay

    // Collisions
    {
        var view = registry.view(struct {
            pos_c: *PositionC,
            collision_c: CollisionC,

            move_c: *MoveC,
            force_c: *ForceC,
        });

        const StableObject = struct {
            pos_c: PositionC,
            collision_c: CollisionC,

            force_c: ?*ForceC,
            move_c: ?*MoveC,
        };

        var stable = registry.view(StableObject);

        while (view.next()) |elem| {
            const pos_c = elem.pos_c;
            const move_c = elem.move_c;
            const collision_c = elem.collision_c;

            // move the thing
            var new_pos = pos_c.pos + move_c.velocity * @splat(2, delta / 1000);

            const bbox = BBox{
                .pos = pos_c.pos,
                .width = collision_c.width,
                .height = collision_c.height,
            };
            const new_bbox = BBox{
                .pos = new_pos,
                .width = collision_c.width,
                .height = collision_c.height,
            };

            elem.force_c.is_airborne = true;

            stable.reset();
            while (stable.next()) |solid| {
                // No move/force component means it can't even be made to move, so we'll
                // think of it as a stable piece of the environment
                if (solid.force_c != null) continue;
                if (solid.move_c != null) continue;

                const found = BBox{
                    .pos = solid.pos_c.pos,
                    .width = solid.collision_c.width,
                    .height = solid.collision_c.height,
                };

                const overlap = new_bbox.overlap(found);
                if (!overlap.result) continue;

                const prev_overlap = bbox.overlap(found);

                if (prev_overlap.x) {
                    if (pos_c.pos[1] < found.pos[1]) {
                        new_pos[1] = found.pos[1] - collision_c.height;
                    } else {
                        new_pos[1] = found.pos[1] + found.height;
                        elem.force_c.is_airborne = false;
                    }

                    move_c.velocity[1] = 0;
                }

                if (prev_overlap.y) {
                    if (pos_c.pos[0] < found.pos[0]) {
                        new_pos[0] = found.pos[0] - collision_c.width;
                    } else {
                        new_pos[0] = found.pos[0] + found.width;
                    }

                    move_c.velocity[0] = 0;
                }
            }

            pos_c.pos = new_pos;

            const cam_pos0 = camera.pos;
            const cam_dims = Vec2{ camera.width, camera.height };
            const cam_pos1 = cam_pos0 + cam_dims;

            const new_x = std.math.clamp(pos_c.pos[0], cam_pos0[0], cam_pos1[0] - collision_c.width);
            if (new_x != pos_c.pos[0])
                move_c.velocity[0] = 0;
            pos_c.pos[0] = new_x;

            const new_y = std.math.clamp(pos_c.pos[1], cam_pos0[1], cam_pos1[1] - collision_c.height);
            if (new_y != pos_c.pos[1])
                move_c.velocity[1] = 0;
            pos_c.pos[1] = new_y;
        }
    }

    {
        var view = registry.view(struct {
            move_c: *MoveC,
            force_c: ForceC,
        });

        while (view.next()) |elem| {
            const move = elem.move_c;
            const force = elem.force_c;

            // apply gravity
            move.velocity += force.accel * @splat(2, delta / 1000);

            // applies a friction force when mario hits the ground.
            if (!force.is_airborne and move.velocity[0] != 0) {
                // Friction is applied in the opposite direction of velocity
                // You cannot gain speed in the opposite direction from friction
                const friction: f32 = force.friction * delta;
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
            render: RenderC,
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
