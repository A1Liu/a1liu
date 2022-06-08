const liu = @import("liu");
const erlang = @import("./erlang.zig");

pub const KeyBox = struct {
    code: u32,
    pressed: bool = false,
    down: bool = false,
};

pub const KeyRow = struct {
    end: u32,
    leftX: i32,
};

pub fn frameCleanup() void {
    for (key_data) |*k| {
        k.pressed = false;
    }
}

pub const keys: []const KeyBox = &key_data;
pub const rows: [3]KeyRow = .{
    .{ .end = 10, .leftX = 5 },
    .{ .end = 19, .leftX = 10 },
    .{ .end = 26, .leftX = 13 },
};

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

export fn onMove(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onClick(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
}

export fn onRightClick(posX: f32, posY: f32) void {
    _ = posX;
    _ = posY;
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
