const std = @import("std");
const liu = @import("liu");

const util = @import("./util.zig");
const mouse = util.mouse;
const rows = util.rows;
const keys = util.keys;
const camera = util.camera;

const erlang = @import("./erlang.zig");
const ext = erlang.ext;
const BBox = erlang.BBox;

const wasm = liu.wasm;
const EntityId = liu.ecs.EntityId;
const Vec2 = liu.Vec2;

pub const Tool = struct {
    const Self = @This();

    const VTable = struct {
        frame: fn (self: *anyopaque) void,
        reset: fn (self: *anyopaque) void,
    };

    name: []const u8,
    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn create(alloc: std.mem.Allocator, obj: anytype) !Self {
        const val = try alloc.create(@TypeOf(obj));
        val.* = obj;

        return init(val);
    }

    pub fn init(obj: anytype) Self {
        const PtrT = @TypeOf(obj);
        const T = std.meta.Child(PtrT);

        return initWithVtable(T, obj, T);
    }

    pub fn initWithVtable(comptime T: type, obj: *T, comptime VtableType: type) Self {
        const info = std.meta.fieldInfo;

        const vtable = comptime VTable{
            .frame = @ptrCast(info(VTable, .frame).field_type, VtableType.frame),
            .reset = @ptrCast(info(VTable, .reset).field_type, VtableType.reset),
        };

        return Self{
            .name = if (@hasDecl(T, "tool_name")) T.tool_name else @typeName(T),
            .ptr = @ptrCast(*anyopaque, obj),
            .vtable = &vtable,
        };
    }

    pub fn reset(self: *Self) void {
        return self.vtable.reset(self.ptr);
    }

    pub fn frame(self: *Self) void {
        return self.vtable.frame(self.ptr);
    }
};

fn makeBox(pos: Vec2) !EntityId {
    const id = try erlang.registry.create("box");
    errdefer erlang.registry.delete(id);

    try erlang.registry.addComponent(id, erlang.PositionC{
        .pos = pos,
    });
    try erlang.registry.addComponent(id, erlang.CollisionC{
        .width = 1,
        .height = 1,
    });
    try erlang.registry.addComponent(id, erlang.RenderC{
        .color = erlang.Vec4{ 0.2, 0.5, 0.3, 1 },
        .sprite_width = 1,
        .sprite_height = 1,
    });

    return id;
}

pub const ClickTool = struct {
    dummy: bool = false,

    pub fn reset(self: *@This()) void {
        _ = self;
    }

    pub fn frame(self: *@This()) void {
        if (!mouse.clicked) return;
        _ = self;

        const pos = @floor(mouse.pos);
        _ = makeBox(pos) catch return;
    }
};

pub const LineTool = struct {
    existing: ?EntityId = null,

    pub fn reset(self: *@This()) void {
        const existing = self.existing orelse return;
        self.existing = null;
        _ = erlang.registry.delete(existing);
    }

    pub fn frame(self: *@This()) void {
        if (mouse.clicked) {
            if (self.existing != null) {
                self.existing = null;
            } else {
                const pos = @floor(mouse.pos);
                self.existing = makeBox(pos) catch return;
            }

            return;
        }
    }
};

pub const DrawTool = struct {
    drawing: bool = false,

    pub fn reset(self: *@This()) void {
        self.drawing = false;
    }

    pub fn frame(self: *@This()) void {
        if (mouse.clicked) {
            self.drawing = !self.drawing;
        }

        if (!self.drawing) return;

        const pos = @floor(mouse.pos);
        const pos1 = @ceil(mouse.pos);
        const bbox = BBox{
            .pos = pos,
            .width = pos1[0] - pos[0],
            .height = pos1[1] - pos[1],
        };

        var view = erlang.registry.view(struct {
            pos_c: erlang.PositionC,
            collision_c: erlang.CollisionC,
            // decide_c: erlang.DecisionC,
        });

        while (view.next()) |elem| {
            // if (elem.decide_c != .player) continue;

            const elem_bbox = BBox.init(elem.pos_c.pos, elem.collision_c);
            if (elem_bbox.overlap(bbox).result) return;
        }

        const new_solid = makeBox(pos) catch return;
        _ = new_solid;
    }
};
