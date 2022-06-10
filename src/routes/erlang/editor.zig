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

    pub fn frame(self: *Self) void {
        return self.vtable.frame(self.ptr);
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

        const new_solid = erlang.registry.create("box") catch return;
        erlang.registry.addComponent(new_solid, erlang.PositionC{
            .pos = pos,
        }) catch erlang.registry.delete(new_solid);
        erlang.registry.addComponent(new_solid, erlang.CollisionC{
            .width = 1,
            .height = 1,
        }) catch erlang.registry.delete(new_solid);
        erlang.registry.addComponent(new_solid, erlang.RenderC{
            .color = erlang.Vec4{ 0.2, 0.5, 0.3, 1 },
            .sprite_width = 1,
            .sprite_height = 1,
        }) catch erlang.registry.delete(new_solid);
    }
};
