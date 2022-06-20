const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const Vec2 = liu.Vec2;

var frame_id: u64 = 0;
var time: f64 = undefined;
var key_data: [256]KeyInfo = [_]KeyInfo{.{}} ** 256;
var dims: @Vector(2, u32) = @Vector(2, u32){ 0, 0 };
var mouse: MouseData = .{};

comptime {
    @export(setDims, .{ .name = "setDims", .linkage = .Strong });
    @export(onScroll, .{ .name = "onScroll", .linkage = .Strong });
    @export(onMove, .{ .name = "onMove", .linkage = .Strong });
    @export(onClick, .{ .name = "onClick", .linkage = .Strong });
    @export(onRightClick, .{ .name = "onRightClick", .linkage = .Strong });
    @export(onKey, .{ .name = "onKey", .linkage = .Strong });
}

pub fn init(timestamp: f64) void {
    time = timestamp;
}

pub fn frameStart(timestamp: f64) FrameInput {
    const value = FrameInput{
        .frame_id = frame_id,
        .delta = @floatCast(f32, timestamp - time),
        .screen_dims = dims,
        .mouse = mouse,
    };

    time = timestamp;
    frame_id += 1;

    return value;
}

pub fn frameCleanup() void {
    for (key_data) |*k| {
        k.pressed = false;
    }

    mouse.scroll_dist = Vec2{ 0, 0 };
    mouse.scroll_tick = @Vector(2, i32){ 0, 0 };
    mouse.left_clicked = false;
    mouse.right_clicked = false;
}

fn setDims(posX: u32, posY: u32) callconv(.C) void {
    dims = @Vector(2, u32){ posX, posY };
}

fn onScroll(deltaX: f32, deltaY_: f32) callconv(.C) void {
    // Y axis grows downwards on the web
    const deltaY = -deltaY_;

    mouse.scroll_dist += Vec2{ deltaX, deltaY };

    const one: f32 = 1;

    if (deltaX != 0) {
        mouse.scroll_tick[0] += @floatToInt(i32, std.math.copysign(one, deltaX));
    }

    if (deltaY != 0) {
        mouse.scroll_tick[1] += @floatToInt(i32, std.math.copysign(one, deltaY));
    }
}

fn onMove(posX: f32, posY: f32) callconv(.C) void {
    mouse.pos = Vec2{ posX, posY };
}

fn onClick(posX: f32, posY: f32) callconv(.C) void {
    onMove(posX, posY);
    mouse.left_clicked = true;
}

fn onRightClick(posX: f32, posY: f32) callconv(.C) void {
    onMove(posX, posY);
    mouse.right_clicked = true;
}

fn onKey(down: bool, code: u8) callconv(.C) void {
    const key = &key_data[code];
    key.pressed = down;
    key.down = down;
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

pub const KeyRow = struct {
    keys: []const KeyCode,
    leftX: i32,
};

const KeyInfo = struct {
    pressed: bool = false,
    down: bool = false,
};

pub const FrameInput = struct {
    frame_id: u64,
    delta: f32,
    screen_dims: @Vector(2, u32),
    mouse: MouseData,

    pub fn key(self: *const @This(), code: KeyCode) KeyInfo {
        _ = self;

        return key_data[code.code()];
    }
};

pub const MouseData = struct {
    pos: Vec2 = Vec2{ 0, 0 },
    scroll_dist: Vec2 = Vec2{ 0, 0 },
    scroll_tick: @Vector(2, i32) = @Vector(2, i32){ 0, 0 },
    left_clicked: bool = false,
    right_clicked: bool = false,
};

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
