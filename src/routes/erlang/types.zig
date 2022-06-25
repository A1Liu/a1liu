const liu = @import("liu");

pub const Vec2 = liu.Vec2;
pub const Vec3 = liu.Vec3;
pub const Vec4 = liu.Vec4;

pub var registry: Registry = undefined;
pub const Registry = liu.ecs.Registry(&.{
    PositionC,
    MoveC,
    RenderC,
    DecisionC,
    ForceC,
    BarC,
});

pub const BBox = struct {
    pos: Vec2,
    width: f32,
    height: f32,

    const Overlap = struct {
        result: bool,
        x: bool,
        y: bool,
    };

    pub fn overlap(self: @This(), other: @This()) Overlap {
        const pos1 = self.pos + Vec2{ self.width, self.height };
        const other_pos1 = other.pos + Vec2{ other.width, other.height };
        const x = self.pos[0] < other_pos1[0] and other.pos[0] < pos1[0];
        const y = self.pos[1] < other_pos1[1] and other.pos[1] < pos1[1];

        return .{
            .result = x and y,
            .y = y,
            .x = x,
        };
    }

    pub fn renderRectVector(self: @This()) @Vector(4, i32) {
        return @Vector(4, i32){
            @floatToInt(i32, @floor(self.pos[0])),
            @floatToInt(i32, @floor(self.pos[1])),
            @floatToInt(i32, @ceil(self.width)),
            @floatToInt(i32, @ceil(self.height)),
        };
    }
};

pub const BarKind = enum { red, blue, green };

pub const RenderC = struct {
    color: Vec4,
    game_visible: bool = true,
    editor_visible: bool = true,
};

pub const SerializeC = struct {
    save_to_file: bool = true,
};

pub const BarC = struct {
    is_spawn: bool,
    kind: BarKind,
};

pub const PositionC = struct {
    bbox: BBox,
};

pub const MoveC = struct {
    velocity: Vec2,
};

pub const ForceC = struct {
    accel: Vec2,
    friction: f32,
    is_airborne: bool = false,
};

pub const DecisionC = struct {
    player: bool,
};
