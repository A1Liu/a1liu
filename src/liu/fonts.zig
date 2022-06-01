const std = @import("std");
const liu = @import("./lib.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// https://github.com/raphlinus/font-rs

pub fn accumulate(alloc: Allocator, src: []const f32) ![]u8 {
    var acc: f32 = 0.0;

    const out = try alloc.alloc(u8, src.len);

    for (src) |c, idx| {
        // This would translate really well to SIMD
        acc += c;
        var y = @fabs(acc);
        y = if (y < 1.0) y else 1.0;
        out[idx] = @floatToInt(u8, 255.0 * y);
    }

    return out;
}

const Point = struct {
    data: liu.Vec2,

    pub fn init(x: f32, y: f32) Point {
        return .{ .data = liu.Vec2{ x, y } };
    }

    pub fn intInit(x: i64, y: i64) Point {
        const xF = @intToFloat(f32, x);
        const yF = @intToFloat(f32, y);

        return .{ .data = liu.Vec2{ xF, yF } };
    }

    pub fn lerp(t0: f32, p0: Point, p1: Point) Point {
        const t = @splat(2, t0);

        return Point{ .data = p0.data + t * (p1.data - p0.data) };
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
        const v1 = liu.Vec2{ p.data[0], p.data[0] };
        const v2 = liu.Vec2{ z.data[2], z.data[3] };
        const v3 = liu.Vec2{ p.data[1], p.data[1] };
        const v4 = liu.Vec2{ z.data[4], z.data[5] };

        return Point{ .data = v0 * v1 + v2 * v3 + v4 };
    }
};

const Raster = struct {
    w: usize,
    h: usize,
    a: []f32,

    pub fn new(w: usize, h: usize) Raster {
        return Raster{
            .w = w,
            .h = h,
            // .a= [0.0; w * h + 4],
        };
    }
};

test "Fonts: basic" {
    const affine = Affine{ .data = .{ 0, 1, 0, 1, 0.5, 0.25 } };
    const p0 = Point.init(1, 0);
    const p1 = Point.init(0, 1);

    _ = Point.lerp(0.5, p0, p1);
    _ = affine.pt(&p1);

    const out = try accumulate(liu.Pages, &.{ 0.1, 0.2 });
    liu.Pages.free(out);
}
