const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const NULL = std.math.maxInt(u32);

pub const EntityId = struct {
    index: u32,
    generation: u32,

    pub const NULL: EntityId = .{ .index = std.math.maxInt(u32), .generation = 0 };
};

const FieldInfo = struct {
    is_optional: bool,
    is_pointer: bool,
    T: type,
};

fn UnwrappedField(comptime FieldT: type) FieldInfo {
    const is_optional = @typeInfo(FieldT) == .Optional;
    const child = switch (@typeInfo(FieldT)) {
        .Optional => |info| info.child,
        else => FieldT,
    };

    const is_pointer = @typeInfo(child) == .Pointer;
    const T = switch (@typeInfo(child)) {
        .Pointer => |info| info.child,
        else => child,
    };

    return .{
        .is_optional = is_optional,
        .is_pointer = is_pointer,
        .T = T,
    };
}

fn RegistryView(comptime Reg: type, comptime InViewType: type) type {
    return struct {
        pub const ViewType = @Type(.{
            .Struct = .{
                .layout = .Auto,
                .decls = &.{},
                .is_tuple = false,
                .fields = std.meta.fields(InViewType) ++ [_]std.builtin.Type.StructField{
                    .{
                        .name = "id",
                        .field_type = EntityId,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(EntityId),
                    },
                    .{
                        .name = "name",
                        .field_type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf([]const u8),
                    },
                },
            },
        });

        const Iter = @This();

        registry: *const Reg,
        index: u32 = 0,

        pub fn read(registry: *const Reg, index: u32) ?ViewType {
            const meta = &registry.dense.items(.meta)[index];

            var value: ViewType = undefined;
            value.id = .{ .index = index, .generation = meta.generation };
            value.name = registry.strings.get(meta.name).?;

            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "name")) continue;

                const unwrapped = UnwrappedField(field.field_type);
                if (unwrapped.is_optional) continue;

                const field_enum = comptime std.meta.stringToEnum(Reg.FieldEnum, field.name) orelse
                    @compileError("field type not registered: " ++
                    "name=" ++ field.name ++ ", type=" ++ @typeName(unwrapped.T));

                const is_set = meta.bitset.isSet(@enumToInt(field_enum));
                if (!is_set) return null;

                const ptr = &registry.dense.items(field_enum)[index];
                @field(value, field.name) = if (unwrapped.is_pointer) ptr else ptr.*;
            }

            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "name")) continue;

                const unwrapped = UnwrappedField(field.field_type);
                if (!unwrapped.is_optional) continue;

                const field_enum = comptime std.meta.stringToEnum(Reg.FieldEnum, field.name) orelse
                    @compileError("field type not registered: " ++
                    "name=" ++ field.name ++ ", type=" ++ @typeName(unwrapped.T));

                const is_set = meta.bitset.isSet(@enumToInt(field_enum));
                @field(value, field.name) = value: {
                    if (!is_set) {
                        break :value null;
                    }

                    const ptr = &registry.dense.items(field_enum)[index];
                    break :value if (unwrapped.is_pointer) ptr else ptr.*;
                };
            }

            return value;
        }

        pub fn get(self: *Iter, id: EntityId) ?ViewType {
            const index = self.registry.indexOf(id) orelse return null;

            return read(self.registry, index);
        }

        pub fn reset(self: *Iter) void {
            self.index = 0;
        }

        pub fn next(self: *Iter) ?ViewType {
            while (self.index < self.registry.dense.len) {
                // this enforces the index increment, even when the return
                // happens below
                defer self.index += 1;

                const meta = &self.registry.dense.items(.meta)[self.index];
                if (meta.generation == NULL) continue;

                const value = read(self.registry, self.index);
                if (value) |v| return v;
            }

            return null;
        }
    };
}

// TODO: creating entity during iteration
// TODO add back sparse (commented out code is wrong so rewrite it lol)

// comptime InSparse: []const type,
pub fn Registry(comptime InDense: type) type {
    const Fields = @typeInfo(InDense).Struct.fields;

    return struct {
        const Self = @This();

        pub const FieldEnum = std.meta.FieldEnum(Dense);
        pub const Meta = struct {
            name: u32, // use this field to store the next freelist element
            generation: u32,
            bitset: std.StaticBitSet(Fields.len),
        };

        const InDense = InDense;

        // Field ordering matters here, the meta field is listed last, so it
        // gets the highest enum integer value; this makes it safe to do
        // @enumToInt on the meta bitset
        const Dense = @Type(.{
            .Struct = .{
                .layout = .Auto,
                .decls = &.{},
                .is_tuple = false,
                .fields = Fields ++ [_]std.builtin.Type.StructField{
                    .{
                        .name = "meta",
                        .field_type = Meta,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(Meta),
                    },
                },
            },
        });

        alloc: std.mem.Allocator,
        strings: liu.StringTable,
        generation: u32,

        dense: std.MultiArrayList(Dense),

        count: u32,
        free_head: u32,

        pub fn init(capacity: u32, alloc: std.mem.Allocator) !Self {
            var dense = std.MultiArrayList(Dense){};
            try dense.ensureUnusedCapacity(alloc, capacity);

            return Self{
                .dense = dense,
                .count = 0,
                .generation = 1,
                .strings = .{},
                .alloc = alloc,
                .free_head = NULL,
            };
        }

        pub fn deinit(self: *Self) void {
            self.strings.deinit(self.alloc);
            self.dense.deinit(self.alloc);
        }

        pub fn create(self: *Self, name: []const u8) !EntityId {
            self.count += 1;
            errdefer self.count -= 1;

            const index = index: {
                if (self.free_head != NULL) {
                    const index = self.free_head;
                    const meta = &self.dense.items(.meta)[self.free_head];
                    self.free_head = meta.name;

                    break :index index;
                }

                const index = self.dense.len;
                try self.dense.append(self.alloc, undefined);

                break :index index;
            };

            const name_id = try self.strings.add(self.alloc, name);
            errdefer self.strings.delete(name_id);

            const meta = &self.dense.items(.meta)[index];
            meta.name = name_id;
            meta.generation = self.generation;
            meta.bitset = std.StaticBitSet(Fields.len).initEmpty();

            return EntityId{ .index = @truncate(u32, index), .generation = self.generation };
        }

        pub fn delete(self: *Self, id: EntityId) bool {
            const index = self.indexOf(id) orelse return false;
            self.count -= 1;

            const meta = &self.dense.items(.meta)[index];
            self.strings.delete(meta.name);

            if (self.count == 0) {
                self.dense.len = 0;
                self.free_head = NULL;

                // Should generation be reset here? Technically someone could
                // be holding an entity ID which would then false-positive
                //
                // No, it should not be reset, for that exact reason.

                return true;
            }

            meta.generation = NULL;
            meta.name = self.free_head;

            self.free_head = id.index;
            self.generation += 1;

            return true;
        }

        pub fn addComponent(self: *Self, id: EntityId, comptime field: FieldEnum) ?*std.meta.fieldInfo(Dense, field).field_type {
            if (field == .meta) @compileError("Tried to add a Meta component");

            const index = self.indexOf(id) orelse return null;

            // Previously, we deferred here so that we can read the previous value
            // before returning; we don't return whether the component was there
            // anymore, so now this is just here for whatever, idk
            const meta = &self.dense.items(.meta)[index];
            defer meta.bitset.set(@enumToInt(field));

            const elements = self.dense.items(field);
            return &elements[index];
        }

        pub fn view(self: *Self, comptime ViewType: type) RegistryView(Self, ViewType) {
            return .{ .registry = self };
        }

        fn indexOf(self: *const Self, id: EntityId) ?u32 {
            if (id.index >= self.dense.len) return null;

            const meta_slice = self.dense.items(.meta);

            const meta = &meta_slice[id.index];
            if (meta.generation > id.generation) return null;

            return id.index;
        }
    };
}

test "Registry: iterate" {
    const TransformComponent = struct { i: u32 };
    const MoveComponent = struct {};
    const Mep = struct {
        blarg: u32,
    };

    const RegistryType = Registry(struct {
        transform: TransformComponent,
        move: MoveComponent,
        mep: Mep,
    });

    var registry = try RegistryType.init(256, liu.Pages);
    defer registry.deinit();

    var i: u32 = 0;
    while (i < 257) : (i += 1) {
        const meh = try registry.create("meh");
        // success =
        registry.addComponent(meh, .transform).?.* = .{
            .i = meh.index,
        };
        registry.addComponent(meh, .mep).?.* = .{
            .blarg = meh.index,
        };
        // try std.testing.expect(success);
    }

    try std.testing.expect(registry.dense.len == 257);
    try std.testing.expect(registry.dense.capacity > 256);

    const View = struct {
        transform: TransformComponent,
        move: ?*MoveComponent,
        mep: ?Mep,
    };

    var view = registry.view(View);
    while (view.next()) |elem| {
        try std.testing.expect(elem.name.len == 3);

        try std.testing.expect(elem.transform.i == elem.id.index);

        if (elem.mep) |m|
            try std.testing.expect(m.blarg == elem.id.index)
        else
            try std.testing.expect(false);

        try std.testing.expect(elem.move == null);
    }
}

test "Registry: delete" {
    const TransformComponent = struct {};
    const MoveComponent = struct {};

    const RegistryType = Registry(struct {
        transform: TransformComponent,
        move: MoveComponent,
    });

    var registry = try RegistryType.init(256, liu.Pages);
    defer registry.deinit();

    const View = struct {
        transform: ?TransformComponent,
        move: ?*MoveComponent,
    };

    _ = try registry.create("meh");
    const deh = try registry.create("dehh");

    try std.testing.expect(registry.delete(deh));

    var view = registry.view(View);
    var count: u32 = 0;
    while (view.next()) |elem| {
        try std.testing.expect(elem.name.len == 3);
        count += 1;
    }

    try std.testing.expect(count == 1);

    view.reset();
}
