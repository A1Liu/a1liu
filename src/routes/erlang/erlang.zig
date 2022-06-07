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
    extern fn fillStyle(r: f32, g: f32, b: f32) void;
    extern fn fillRect(x: u32, y: u32, width: u32, height: u32) void;
    extern fn setFont(font: wasm.Obj) void;
    extern fn fillText(text: wasm.Obj, x: u32, y: u32) void;
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
    dims[0] = posX;
    dims[1] = posY;
}

export fn onRightClick(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onKey(down: bool, code: u32) void {
    var begin: u32 = 0;

    for (rows) |row| {
        const end = row.end;

        for (keys[begin..row.end]) |*key| {
            if (code == key.code) {
                key.pressed = down;
                return;
            }
        }

        begin = end;
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

export fn init(timestamp: f64) void {
    wasm.initIfNecessary();

    initErr(timestamp) catch @panic("meh");

    wasm.post(.info, "WASM initialized!", .{});
}

fn initErr(timestamp: f64) !void {
    previous_time = timestamp;
    large_font = wasm.make.fmt(.manual, "bold 48px sans-serif", .{});
    small_font = wasm.make.fmt(.manual, "10px sans-serif", .{});
}

var previous_time: f64 = undefined;
var dims: Vec2 = [_]f32{ 0, 0 };

var large_font: wasm.Obj = undefined;
var small_font: wasm.Obj = undefined;

export fn run(timestamp: f64) void {
    const diff = timestamp - previous_time;
    defer previous_time = timestamp;

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    ext.fillStyle(0.5, 0.5, 0.5);

    ext.setFont(large_font);

    const fps_message = wasm.out.fmt("FPS: {d:.2}", .{1000 / diff});
    ext.fillText(fps_message, 5, 160);

    ext.setFont(small_font);

    var begin: u32 = 0;
    var topY: u32 = 5;

    for (rows) |row| {
        var leftX = row.leftX;
        const end = row.end;

        for (keys[begin..row.end]) |key| {
            const color: f32 = if (key.pressed) 0.3 else 0.5;
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

const KeyBox = struct {
    code: u32,
    pressed: bool = false,
};

const KeyRow = struct {
    end: u32,
    leftX: u32,
};

const rows: [3]KeyRow = .{
    .{ .end = 10, .leftX = 5 },
    .{ .end = 19, .leftX = 10 },
    .{ .end = 26, .leftX = 13 },
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
