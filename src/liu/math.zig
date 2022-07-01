const std = @import("std");

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec4 = @Vector(4, f32);

pub fn vec2Append(v: Vec2, third: f32) Vec3 {
    var vec: Vec3 = undefined;
    vec[0] = v[0];
    vec[1] = v[1];
    vec[2] = third;

    return vec;
}

pub fn norm2(v: Vec2) Vec2 {
    const out = @reduce(.Sum, v * v);

    return v / @sqrt(out);
}

pub fn cross(a: Vec3, b: Vec3) Vec3 {
    const a1 = Vec3{ a[1], a[2], a[0] };
    const b2 = Vec3{ b[2], b[0], b[1] };

    const a2 = Vec3{ a[2], a[0], a[1] };
    const b1 = Vec3{ b[1], b[2], b[0] };

    return (a1 * b2) - (a2 * b1);

    // var vec: Vec3 = undefined;
    // vec[0] = a[1] * b[2] - a[2] * b[1];
    // vec[1] = a[2] * b[0] - a[0] * b[2];
    // vec[2] = a[0] * b[1] - a[1] * b[0];

    // return vec;
}

pub fn dot(a: Vec3, b: Vec3) f32 {
    var vec: Vec3 = a * b;

    return vec[0] + vec[1] + vec[2];
}

// Möller–Trumbore algorithm for triangle-ray intersection algorithm
pub fn intersect(EPSILON: f32, ray: Vec3, ray_origin: Vec3, triangle: [3]Vec3) bool {
    const vert0 = triangle[0];
    const vert1 = triangle[1];
    const vert2 = triangle[2];

    const edge1 = vert1 - vert0;
    const edge2 = vert2 - vert0;

    const h = cross(ray, edge2);
    const a = dot(edge1, h);

    if (a > -EPSILON and a < EPSILON)
        return false; // This ray is parallel to this triangle.

    const f = 1.0 / a;
    const s = ray_origin - vert0;
    const u = f * dot(s, h);
    if (u < 0.0 or u > 1.0)
        return false;

    const q = cross(s, edge1);
    const v = f * dot(ray, q);
    if (v < 0.0 or u + v > 1.0)
        return false;

    // At this stage we can compute t to find out where the intersection point
    // is on the line.
    const t = f * dot(edge2, q);
    if (t > EPSILON) { // ray intersection
        return true;
    } else { // there is a line intersection but not a ray intersection.
        return false;
    }
}

// Function to find modulo inverse of a
pub fn modInverse(comptime T: type, a: T, m: T) ?T {
    const result = gcdExtended(T, a, m);
    if (result.gcd != 1) return null;

    // m is added to handle negative x
    return (result.x % m +% m) % m;
}

fn GcdResult(comptime T: type) type {
    return struct {
        gcd: T,
        x: T,
        y: T,
    };
}

// Function for extended Euclidean Algorithm
pub fn gcdExtended(comptime T: type, a: T, b: T) GcdResult(T) {
    if (a == 0) // Base Case
        return .{ .gcd = b, .x = 0, .y = 1 };

    // To store results of recursive call
    const result = gcdExtended(T, b % a, a);

    // Update x and y using results of recursive call
    return .{
        .gcd = result.gcd,
        .x = result.y -% (b / a) *% result.x,
        .y = result.x,
    };
}

test "Math: GCD" {
    try std.testing.expectEqual(modInverse(u32, 3, 11), 4);

    try std.testing.expectEqual(modInverse(u64, 0x01000193, 1 << 32), 0x359c449b);
    try std.testing.expectEqual(@as(u32, 0x01000193) *% 0x359c449b, 1);

    const a_array = [_]u128{
        16294208416658607535,
        10451216379200822465,
        11317887983584761797,
    };

    const b_array = [_]u128{
        817831822087661903,
        10888168410540946241,
        11674727387005193997,
    };

    for (a_array) |a, i| {
        const b = b_array[i];
        try std.testing.expectEqual(modInverse(u128, a, 1 << 64), b);
        try std.testing.expectEqual(@intCast(u64, a) *% @intCast(u64, b), 1);
    }

    // try std.testing.expectEqual(@as(u32, 0), 1);
}
