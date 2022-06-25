const liu = @import("liu");

pub const Vec2 = liu.Vec2;
pub const Vec3 = liu.Vec3;
pub const Vec4 = liu.Vec4;
pub const EntityId = liu.ecs.EntityId;

pub var registry: Registry = undefined;
pub const Registry = liu.ecs.Registry(&.{
    PositionC,
    MoveC,
    RenderC,
    DecisionC,
    ForceC,
    BarC,
    SaveC,
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

    pub fn unitSquareAt(pos: Vec2) @This() {
        return BBox{
            .pos = @floor(pos),
            .width = 1,
            .height = 1,
        };
    }

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

pub const BarKind = enum(u8) {
    red,
    green,
    blue,

    pub fn spawnName(self: @This()) []const u8 {
        switch (self) {
            .red => return "spawn_red",
            .green => return "spawn_green",
            .blue => return "spawn_blue",
        }
    }

    pub fn barName(self: @This()) []const u8 {
        switch (self) {
            .red => return "bar_red",
            .green => return "bar_green",
            .blue => return "bar_blue",
        }
    }
};

pub const RenderC = struct {
    color: Vec4,
    game_visible: bool = true,
    editor_visible: bool = true,
};

pub const SaveC = struct {};

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

pub fn unitSquareBBoxForPos(pos: Vec2) BBox {
    return BBox{
        .pos = @floor(pos),
        .width = 1,
        .height = 1,
    };
}

pub fn boxWillCollide(bbox: BBox) bool {
    var view = registry.view(struct {
        pos_c: PositionC,
        force_c: ?*const ForceC,
    });

    while (view.next()) |elem| {
        if (elem.force_c == null) continue;

        const overlap = elem.pos_c.bbox.overlap(bbox);
        if (overlap.result) return true;
    }

    return false;
}

const dark_green = Vec4{ 0.2, 0.5, 0.3, 1 };
const norm_color: Vec4 = Vec4{ 0.3, 0.3, 0.3, 0.6 };
pub fn makeBox(pos: Vec2) !EntityId {
    const bbox = BBox{ .pos = pos, .width = 1, .height = 1 };
    if (boxWillCollide(bbox)) return error.Collision;

    const id = try registry.create("box");
    errdefer registry.delete(id);

    try registry.addComponent(id, PositionC{
        .bbox = bbox,
    });

    try registry.addComponent(id, RenderC{
        .color = dark_green,
    });

    try registry.addComponent(id, SaveC{});

    return id;
}

pub fn makeSpawn(bar: BarKind, pos: Vec2) !EntityId {
    const i = @enumToInt(bar);

    var color = norm_color;
    color[i] = 0.8;

    const box = try registry.create("spawn");

    try registry.addComponent(box, PositionC{ .bbox = .{
        .pos = pos,
        .width = 1,
        .height = 3,
    } });
    try registry.addComponent(box, RenderC{
        .color = color,
    });

    try registry.addComponent(box, BarC{
        .is_spawn = true,
        .kind = bar,
    });

    try registry.addComponent(box, SaveC{});
}

pub fn makeBar(bar: BarKind, pos: Vec2) !EntityId {
    const i = @enumToInt(bar);

    var color = norm_color;
    color[i] = 1;

    const box = try registry.create("bar");
    try registry.addComponent(box, PositionC{ .bbox = .{
        .pos = pos,
        .width = 0.5,
        .height = 2.75,
    } });
    try registry.addComponent(box, RenderC{
        .color = color,
    });
    try registry.addComponent(box, MoveC{
        .velocity = Vec2{ 0, 0 },
    });
    try registry.addComponent(box, DecisionC{ .player = true });

    try registry.addComponent(box, ForceC{
        .accel = Vec2{ 0, -14 },
        .friction = 0.05,
    });

    try registry.addComponent(box, BarC{
        .is_spawn = false,
        .kind = bar,
    });
}
