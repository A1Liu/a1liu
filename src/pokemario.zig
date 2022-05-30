const Vector3 = @Vector(3, f32);
const Vector4 = @Vector(4, f32);

const TransformComponent = struct {
    position: Vector3,
    rotation: Vector4,
    scale: f32,
};

const MoveComponent = struct {
    direction: Vector3, // normalized
    speed: f32,
};
