const std = @import("std");
const liu = @import("liu");
const erlang = @import("./erlang.zig");
const ext = erlang.ext;
const BBox = erlang.BBox;

const wasm = liu.wasm;
const Vec2 = liu.Vec2;

pub const camera: *const Camera = &camera_data;
var camera_data: Camera = .{};

pub fn frameCleanup() void {
    for (key_data) |*k| {
        k.pressed = false;
    }
    mouse_data.scroll_dist = Vec2{ 0, 0 };
    mouse_data.scroll_tick = @Vector(2, i32){ 0, 0 };
    mouse_data.clicked = false;
}

pub const mouse: *const MouseData = &mouse_data;
pub const keys: []const KeyBox = &key_data;
pub const rows: [3]KeyRow = .{
    .{ .end = 10, .leftX = 5 },
    .{ .end = 19, .leftX = 11 },
    .{ .end = 26, .leftX = 27 },
};

var mouse_data: MouseData = .{};

var key_data: [26]KeyBox = [_]KeyBox{
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

const KeyBox = struct {
    code: u32,
    pressed: bool = false,
    down: bool = false,
};

const KeyRow = struct {
    end: u32,
    leftX: i32,
};

const MouseData = struct {
    pos: Vec2 = Vec2{ 0, 0 },
    scroll_dist: Vec2 = Vec2{ 0, 0 },
    scroll_tick: @Vector(2, i32) = @Vector(2, i32){ 0, 0 },
    clicked: bool = false,
};

pub fn moveCamera(pos: Vec2) void {
    camera_data.pos = pos - Vec2{ camera_data.width / 2, camera_data.height / 2 };
}

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

export fn onScroll(deltaX: f32, deltaY: f32) void {
    mouse_data.scroll_dist += Vec2{ deltaX, -deltaY };

    if (deltaX != 0) {
        mouse_data.scroll_tick[0] += @floatToInt(i32, std.math.copysign(f32, 1, deltaX));
    }

    if (deltaY != 0) {
        mouse_data.scroll_tick[1] += @floatToInt(i32, std.math.copysign(f32, 1, deltaY));
    }
}

export fn onMove(posX: f32, posY: f32) void {
    const pos = Vec2{ posX, posY };
    const world_pos = camera_data.screenToWorldCoordinates(pos);

    mouse_data.pos = world_pos;
}

export fn onClick(posX: f32, posY: f32) void {
    onMove(posX, posY);
    mouse_data.clicked = true;
}

export fn onRightClick(posX: f32, posY: f32) void {
    onMove(posX, posY);
}

export fn onKey(down: bool, code: u32) void {
    var begin: u32 = 0;

    for (rows) |row| {
        const end = row.end;

        for (key_data[begin..row.end]) |*key| {
            if (code == key.code) {
                key.pressed = down;
                key.down = down;
                return;
            }
        }

        begin = end;
    }
}
