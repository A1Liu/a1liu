const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const EPSILON: f32 = 0.000001;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// https://github.com/raphlinus/font-rs

pub fn accumulate(alloc: Allocator, src: []const f32) ![]u8 {
    var acc: f32 = 0.0;

    const out = try alloc.alloc(u8, src.len);

    for (src) |c, idx| {
        acc += c;
        var y = @fabs(acc);
        y = if (y < 1.0) y else 1.0;
        out[idx] = @floatToInt(u8, 255.0 * y);
    }

    return out;
}

const Point = struct {
    x: f32,
    y: f32,

    pub fn intInit(x: i64, y: i64) Point {
        const xF = @intToFloat(f32, x);
        const yF = @intToFloat(f32, y);

        return .{ .x = xF, .y = yF };
    }

    pub fn lerp(t0: f32, p0: Point, p1: Point) Point {
        const t = @splat(2, t0);
        const d0 = liu.Vec2{ p0.x, p0.y };
        const d1 = liu.Vec2{ p1.x, p1.y };

        const data = d0 + t * (d1 - d0);
        return Point{ .x = data[0], .y = data[1] };
    }
};

const Affine = struct {
    data: [6]f32,

    pub fn concat(t1: *const Affine, t2: *const Affine) Affine {
        _ = t1;
        _ = t2;
        const Vec6 = @Vector(6, f32);

        const v0 = Vec6{ t1[0], t1[1], t1[0], t1[1], t1[0], t1[1] };
        const v1 = Vec6{ t2[0], t2[0], t2[2], t2[2], t2[4], t2[4] };
        const v2 = Vec6{ t1[2], t1[3], t1[2], t1[3], t1[2], t1[3] };
        const v3 = Vec6{ t2[1], t2[1], t2[3], t2[3], t2[5], t2[5] };

        var out = v0 * v1 + v2 * v3;
        out[4] += t1[4];
        out[5] += t1[5];

        return Affine{ .data = out };
    }

    pub fn pt(z: *const Affine, p: *const Point) Point {
        const v0 = liu.Vec2{ z.data[0], z.data[1] };
        const v1 = liu.Vec2{ p.x, p.x };
        const v2 = liu.Vec2{ z.data[2], z.data[3] };
        const v3 = liu.Vec2{ p.y, p.y };
        const v4 = liu.Vec2{ z.data[4], z.data[5] };

        const data = v0 * v1 + v2 * v3 + v4;
        return Point{ .x = data[0], .y = data[1] };
    }
};

const Metrics = struct {
    l: i32,
    t: i32,
    r: i32,
    b: i32,

    pub fn width(self: *const Metrics) usize {
        return @intCast(usize, self.r - self.l);
    }

    pub fn height(self: *const Metrics) usize {
        return @intCast(usize, self.b - self.t);
    }
};

pub const VMetrics = struct {
    ascent: f32,
    descent: f32,
    line_gap: f32,
};

pub const HMetrics = struct {
    advance_width: f32,
    left_side_bearing: f32,
};

const Raster = struct {
    w: usize,
    h: usize,
    a: []f32,

    pub fn init(alloc: Allocator, w: usize, h: usize) !Raster {
        const a = try alloc.alloc(f32, w * h + 4);
        std.mem.set(f32, a, 0.0);

        return Raster{ .w = w, .h = h, .a = a };
    }

    pub fn drawLine(self: *Raster, _p0: Point, _p1: Point) void {
        if (@fabs(_p0.y - _p1.y) <= EPSILON) {
            return;
        }

        var p0 = _p0;
        var p1 = _p1;

        const dir: f32 = if (p0.y < p1.y) 1.0 else value: {
            p0 = _p1;
            p1 = _p0;

            break :value -1.0;
        };

        const dxdy = (p1.x - p0.x) / (p1.y - p0.y);
        var x = p0.x;
        if (p0.y < 0.0) {
            x -= p0.y * dxdy;
        }

        const h_f32 = @intToFloat(f32, self.h);
        const max = @floatToInt(usize, std.math.min(h_f32, @ceil(p1.y)));

        //  Raph says:  "note: implicit max of 0 because usize (TODO: really true?)"
        // Raph means:  Who tf knows. Wouldn't it be the MIN that's zero? Also,
        //              doesn't your coordinate system start at zero anyways?
        var y: usize = @floatToInt(usize, p0.y);

        while (y < max) : (y += 1) {
            const linestart = y * self.w;

            const y_plus_1 = @intToFloat(f32, y + 1);
            const y_f32 = @intToFloat(f32, y);

            const dy = std.math.min(y_plus_1, p1.y) - std.math.max(y_f32, p0.y);
            const d = dy * dir;

            const xnext = x + dxdy * dy;

            var x0 = xnext;
            var x1 = x;
            if (x < xnext) {
                x0 = x;
                x1 = xnext;
            }

            const x0floor = @floor(x0);
            const x0i = @floatToInt(i32, x0floor);
            const x1ceil = @ceil(x1);
            const x1i = @floatToInt(i32, x1ceil);

            const linestart_x0i = @intCast(isize, linestart) + x0i;
            if (linestart_x0i < 0) {
                continue; // oob index
            }

            const linestart_x0 = @intCast(usize, linestart_x0i);

            if (x1i <= x0i + 1) {
                const xmf = 0.5 * (x + xnext) - x0floor;

                self.a[linestart_x0] += d - d * xmf;
                self.a[linestart_x0 + 1] += d * xmf;
            } else {
                const s = 1.0 / (x1 - x0);
                const x0f = x0 - x0floor;
                const a0 = 0.5 * s * (1.0 - x0f) * (1.0 - x0f);
                const x1f = x1 - x1ceil + 1.0;
                const am = 0.5 * s * x1f * x1f;

                self.a[linestart_x0] += d * a0;

                if (x1i == x0i + 2) {
                    self.a[linestart_x0 + 1] += d * (1.0 - a0 - am);
                } else {
                    const a1 = s * (1.5 - x0f);
                    self.a[linestart_x0 + 1] += d * (a1 - a0);

                    var xi: usize = @intCast(usize, x0i) + 2;

                    while (xi < x1i - 1) : (xi += 1) {
                        self.a[linestart + xi] += d * s;
                    }

                    const a2 = a1 + @intToFloat(f32, x1i - x0i - 3) * s;
                    self.a[linestart + @intCast(usize, x1i - 1)] += d * (1.0 - a2 - am);
                }

                self.a[linestart + @intCast(usize, x1i)] += d * am;
            }

            x = xnext;
        }
    }
};

const FontParseError = error{
    HeaderInvalid,
    OffsetInvalid,
    OffsetLengthInvalid,
};

const native_endian = builtin.target.cpu.arch.endian();
fn read(bytes: []const u8, comptime T: type) ?T {
    const Size = @sizeOf(T);

    if (bytes.len < Size) return null;

    switch (@typeInfo(T)) {
        .Int => {
            var value: T = @bitCast(T, bytes[0..Size].*);
            if (native_endian != .Big) value = @byteSwap(T, value);

            return value;
        },

        else => @compileError("input type is not allowed (only allows integers right now)"),
    }
}

const Font = struct {
    version: u32,
    head: []const u8,
    maxp: []const u8,

    pub fn init(data: []const u8) FontParseError!Font {
        const HeadErr = error.HeaderInvalid;
        const version = read(data[0..], u32) orelse return HeadErr;
        const num_tables = read(data[4..], u16) orelse return HeadErr;

        const Tag = enum(u32) { head, maxp, _ };
        const Count = std.meta.fields(Tag).len;
        var tags: [Count]?[]const u8 = .{null} ** Count;

        var i: u16 = 0;
        table_loop: while (i < num_tables) : (i += 1) {
            const header = data[12 + i * 16 ..][0..16];

            const offset = read(header[8..], u32) orelse return HeadErr;
            const length = read(header[12..], u32) orelse return HeadErr;

            if (offset > data.len) return error.OffsetInvalid;
            if (offset + length > data.len) return error.OffsetLengthInvalid;

            const table_data = data[offset..(offset + length)];

            if (std.mem.eql(u8, header[0..4], "head")) {
                tags[@enumToInt(Tag.head)] = table_data;
                continue :table_loop;
            }

            if (std.mem.eql(u8, header[0..4], "maxp")) {
                tags[@enumToInt(Tag.maxp)] = table_data;
                continue :table_loop;
            }

            // This breaks... idk why
            // inline for (comptime std.meta.fields(Tag)) |field| {
            //     if (std.mem.eql(u8, header[0..4], field.name)) {
            //         tags[field.value] = table_data;
            //         continue :table_loop;
            //     }
            // }
        }

        return Font{
            .version = version,
            .head = tags[@enumToInt(Tag.head)] orelse return HeadErr,
            .maxp = tags[@enumToInt(Tag.maxp)] orelse return HeadErr,
        };
    }
};

test "Fonts: basic" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const bytes = @embedFile("font-rs/fonts/notomono-hinted/NotoMono-Regular.ttf");

    const f = try Font.init(bytes);
    _ = f;

    const affine = Affine{ .data = .{ 0, 1, 0, 1, 0.5, 0.25 } };
    const p0 = Point{ .x = 1, .y = 0 };
    const p1 = Point{ .x = 0, .y = 1 };

    var raster = try Raster.init(liu.Temp, 100, 100);
    raster.drawLine(p0, p1);

    _ = Point.lerp(0.5, p0, p1);
    _ = affine.pt(&p1);

    const out = try accumulate(liu.Temp, raster.a);
    _ = out;
}
