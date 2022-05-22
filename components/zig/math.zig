pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f32);

pub fn vec2Append(v: Vec2, third: f32) Vec3 {
    var vec: Vec3 = undefined;
    vec[0] = v[0];
    vec[1] = v[1];
    vec[2] = third;

    return vec;
}

pub fn cross(a: Vec3, b: Vec3) Vec3 {
    var vec: Vec3 = undefined;
    vec[0] = a[1] * b[2] - a[2] * b[1];
    vec[1] = a[2] * b[0] - a[0] * b[2];
    vec[2] = a[0] * b[1] - a[1] * b[0];

    return vec;
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
