const std = @import("std");
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

        return Point{ .data = d0 + t * (d1 - d0) };
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

        return Point{ .data = v0 * v1 + v2 * v3 + v4 };
    }
};

const Raster = struct {
    w: usize,
    h: usize,
    a: []f32,

    pub fn new(alloc: Allocator, w: usize, h: usize) !Raster {
        const a = try alloc.alloc(f32, w * h + 4);
        std.mem.set(f32, a, 0.0);

        return Raster{ .w = w, .h = h, .a = a };
    }

    pub fn drawLine(self: *Raster, _p0: Point, _p1: Point) void {
        var p0 = _p0;
        var p1 = _p1;

        if (@fabs(p0.y - p1.y) <= EPSILON) {
            return;
        }

        var dir = if (p0.y < p1.y) 1.0 else value: {
            p0 = _p1;
            p1 = _p0;

            break :value -1.0;
        };

        _ = self;
        _ = dir;

        const dxdy = (p1.x - p0.x) / (p1.y - p0.y);
        _ = dxdy;
        // let mut x = p0.x;
        // let y0 = p0.y as usize; // note: implicit max of 0 because usize (TODO: really true?)
        // if p0.y < 0.0 {
        //     x -= p0.y * dxdy;
        // }
        // for y in y0..self.h.min(p1.y.ceil() as usize) {
        //     let linestart = y * self.w;
        //     let dy = ((y + 1) as f32).min(p1.y) - (y as f32).max(p0.y);
        //     let xnext = x + dxdy * dy;
        //     let d = dy * dir;
        //     let (x0, x1) = if x < xnext { (x, xnext) } else { (xnext, x) };
        //     let x0floor = x0.floor();
        //     let x0i = x0floor as i32;
        //     let x1ceil = x1.ceil();
        //     let x1i = x1ceil as i32;
        //     if x1i <= x0i + 1 {
        //         let xmf = 0.5 * (x + xnext) - x0floor;
        //         let linestart_x0i = linestart as isize + x0i as isize;
        //         if linestart_x0i < 0 {
        //             continue; // oob index
        //         }
        //         self.a[linestart_x0i as usize] += d - d * xmf;
        //         self.a[linestart_x0i as usize + 1] += d * xmf;
        //     } else {
        //         let s = (x1 - x0).recip();
        //         let x0f = x0 - x0floor;
        //         let a0 = 0.5 * s * (1.0 - x0f) * (1.0 - x0f);
        //         let x1f = x1 - x1ceil + 1.0;
        //         let am = 0.5 * s * x1f * x1f;
        //         let linestart_x0i = linestart as isize + x0i as isize;
        //         if linestart_x0i < 0 {
        //             continue; // oob index
        //         }
        //         self.a[linestart_x0i as usize] += d * a0;
        //         if x1i == x0i + 2 {
        //             self.a[linestart_x0i as usize + 1] += d * (1.0 - a0 - am);
        //         } else {
        //             let a1 = s * (1.5 - x0f);
        //             self.a[linestart_x0i as usize + 1] += d * (a1 - a0);
        //             for xi in x0i + 2..x1i - 1 {
        //                 self.a[linestart + xi as usize] += d * s;
        //             }
        //             let a2 = a1 + (x1i - x0i - 3) as f32 * s;
        //             self.a[linestart + (x1i - 1) as usize] += d * (1.0 - a2 - am);
        //         }
        //         self.a[linestart + x1i as usize] += d * am;
        //     }
        //     x = xnext;
        // }
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
