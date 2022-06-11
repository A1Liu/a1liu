const std = @import("std");
const liu = @import("liu");
const erlang = @import("./erlang.zig");
const ext = erlang.ext;
const BBox = erlang.BBox;

const wasm = liu.wasm;
const Vec2 = liu.Vec2;

pub const KeyCode = enum(u8) {
    space = ' ',

    comma = ',',
    period = '.',
    slash = '/',

    digit0 = '0',
    digit1,
    digit2,
    digit3,
    digit4,
    digit5,
    digit6,
    digit7,
    digit8,
    digit9,

    semicolon = ';',

    key_a = 'A',
    key_b,
    key_c,
    key_d,
    key_e,
    key_f,
    key_g,
    key_h,
    key_i,
    key_j,
    key_k,
    key_l,
    key_m,
    key_n,
    key_o,
    key_p,
    key_q,
    key_r,
    key_s,
    key_t,
    key_u,
    key_v,
    key_w,
    key_x,
    key_y,
    key_z,

    arrow_up = 128,
    arrow_down,
    arrow_left,
    arrow_right,

    pub fn code(self: @This()) u8 {
        return @enumToInt(self);
    }
};

pub const camera: *const Camera = &camera_data;
pub const rows: [3]KeyRow = .{
    .{
        .leftX = 5,
        .keys = &[_]KeyCode{
            .key_q,
            .key_w,
            .key_e,
            .key_r,
            .key_t,
            .key_y,
            .key_u,
            .key_i,
            .key_o,
            .key_p,
        },
    },
    .{
        .leftX = 11,
        .keys = &[_]KeyCode{
            .key_a,
            .key_s,
            .key_d,
            .key_f,
            .key_g,
            .key_h,
            .key_j,
            .key_k,
            .key_l,
            .semicolon,
        },
    },
    .{
        .leftX = 27,
        .keys = &[_]KeyCode{
            .key_z,
            .key_x,
            .key_c,
            .key_v,
            .key_b,
            .key_n,
            .key_m,
            .comma,
            .period,
            .slash,
        },
    },
};

var frame_id: u64 = 0;
var camera_data: Camera = .{};
var time: f64 = undefined;
var key_data: [256]KeyInfo = [_]KeyInfo{.{}} ** 256;
var mouse_data: MouseData = .{};

const KeyInfo = struct {
    pressed: bool = false,
    down: bool = false,
};

pub const FrameInput = struct {
    frame_id: u64,
    delta: f32,
    mouse: *const MouseData,

    pub fn key(self: *const @This(), code: KeyCode) KeyInfo {
        _ = self;

        return key_data[code.code()];
    }
};

pub fn init(timestamp: f64) void {
    time = timestamp;
}

pub fn frameStart(timestamp: f64) FrameInput {
    const value = FrameInput{
        .frame_id = frame_id,
        .delta = @floatCast(f32, timestamp - time),
        .mouse = &mouse_data,
    };

    time = timestamp;
    frame_id += 1;

    return value;
}

pub fn frameCleanup() void {
    for (key_data) |*k| {
        k.pressed = false;
    }

    mouse_data.scroll_dist = Vec2{ 0, 0 };
    mouse_data.scroll_tick = @Vector(2, i32){ 0, 0 };
    mouse_data.left_clicked = false;
    mouse_data.right_clicked = false;
}

const KeyRow = struct {
    keys: []const KeyCode,
    leftX: i32,
};

const MouseData = struct {
    pos: Vec2 = Vec2{ 0, 0 },
    scroll_dist: Vec2 = Vec2{ 0, 0 },
    scroll_tick: @Vector(2, i32) = @Vector(2, i32){ 0, 0 },
    left_clicked: bool = false,
    right_clicked: bool = false,
};

pub fn moveCamera(pos: Vec2) void {
    camera_data.pos = pos - Vec2{ camera_data.width / 2, camera_data.height / 2 };
}

pub const Timer = struct {
    previous: f64,

    pub fn init() @This() {
        return .{ .previous = time };
    }

    pub fn elapsed(self: @This()) f32 {
        return @floatCast(f32, time - self.previous);
    }

    pub fn lap(self: @This()) f32 {
        const delta = self.elapsed();
        self.previous = time;

        return delta;
    }
};

// multiple cameras at once? LOL you can addd a CameraC to ECS registry:
//
// const CameraC = struct {
//     world_to_pixel: f32 = 1,
// };
//
// Unclear how it would interact with setDims, especially if there's multiple
// cameras active

pub const Camera = struct {
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

    fn screenToWorldCoordinates(self: *const Self, pos: Vec2) Vec2 {
        const pos_translated = pos / @splat(2, self.world_to_pixel);
        const pos_camera = Vec2{ pos_translated[0], self.height - pos_translated[1] };

        return pos_camera + self.pos;
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

export fn setDims(posX: u32, posY: u32) void {
    camera_data.setDims(posX, posY);
}

export fn onScroll(deltaX: f32, deltaY_: f32) void {
    // Y axis grows downwards on the web
    const deltaY = -deltaY_;

    mouse_data.scroll_dist += Vec2{ deltaX, deltaY };

    const one: f32 = 1;

    if (deltaX != 0) {
        mouse_data.scroll_tick[0] += @floatToInt(i32, std.math.copysign(one, deltaX));
    }

    if (deltaY != 0) {
        mouse_data.scroll_tick[1] += @floatToInt(i32, std.math.copysign(one, deltaY));
    }
}

export fn onMove(posX: f32, posY: f32) void {
    const pos = Vec2{ posX, posY };
    const world_pos = camera_data.screenToWorldCoordinates(pos);

    mouse_data.pos = world_pos;
}

export fn onClick(posX: f32, posY: f32) void {
    onMove(posX, posY);
    mouse_data.left_clicked = true;
}

export fn onRightClick(posX: f32, posY: f32) void {
    onMove(posX, posY);
    mouse_data.right_clicked = true;
}

export fn onKey(down: bool, code: u8) void {
    const key = &key_data[code];
    key.pressed = down;
    key.down = down;
}
