const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

// https://youtu.be/SFKR5rZBu-8?t=2202

// use bitset for whether a component exists

pub const EntityId = struct {
    index: u32,
    generation: u32,

    pub const NULL: EntityId = .{ .index = std.math.maxInt(u32), .generation = 0 };
};

fn RegistryView(comptime Registry: type, comptime InViewType: type) type {
    return struct {
        pub const ViewType = @Type(.{
            .Struct = .{
                .layout = .Auto,
                .decls = &.{},
                .is_tuple = false,
                .fields = std.meta.fields(InViewType) ++ [_]std.builtin.Type.StructField{
                    .{
                        .name = "id",
                        .field_type = u32,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(u32),
                    },
                    .{
                        .name = "meta",
                        .field_type = *const Registry.Meta,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = @alignOf(*const Registry.Meta),
                    },
                },
            },
        });

        const Iter = @This();

        registry: *Registry,
        index: u32 = 0,

        pub fn read(self: *Iter, index: u32) ViewType {
            const meta = &self.registry.raw(Registry.Meta)[index];

            var value: ViewType = undefined;
            value.id = self.index;
            value.meta = meta;

            inline for (std.meta.fields(ViewType)) |field| {
                if (comptime std.mem.eql(u8, field.name, "id")) continue;
                if (comptime std.mem.eql(u8, field.name, "meta")) continue;

                @field(value, field.name) = value: {
                    const child = switch (@typeInfo(field.field_type)) {
                        .Optional => |info| info.child,
                        else => @compileError("Expected field to be optional, found '" ++
                            @typeName(field.field_type) ++ "'"),
                    };

                    const isPointer = @typeInfo(child) == .Pointer;
                    const T = switch (@typeInfo(child)) {
                        .Pointer => |info| info.child,
                        else => child,
                    };

                    const typeIndex = Registry.typeIndex(T);
                    if (!meta.bitset.isSet(typeIndex)) {
                        break :value null;
                    }

                    const ptr = &self.registry.raw(T)[index];
                    break :value if (isPointer) ptr else ptr.*;
                };
            }

            return value;
        }

        pub fn get(self: *Iter, id: EntityId) ?ViewType {
            const index = self.registry.indexOf(id) orelse return null;
            return self.read(index);
        }

        pub inline fn next(self: *Iter) ?ViewType {
            while (self.index < self.registry.len) {
                // this enforces the index increment, even when the return
                // happens below
                defer self.index += 1;

                const meta = &self.registry.raw(Registry.Meta)[self.index];
                if (meta.generation == std.math.maxInt(u32)) continue;

                const value = self.read(self.index);
                return value;
            }

            return null;
        }
    };
}

pub fn NewRegistryType(comptime InputComponentTypes: []const type) type {
    // NOTE: for now, duplicate component types will just fail to work silently.

    // comptime {
    //     for (ComponentTypes) |t, idx| {
    //         for (ComponentTypes[0..idx]) |prev| {
    //             if (prev == t) std.debug.assert(false);
    //         }
    //     }
    // }

    return struct {
        pub const Meta = struct {
            name: []const u8, // use the len field to store the generation
            generation: u32,
            bitset: std.StaticBitSet(Components.len),
        };

        const Self = @This();

        const Components = [_]type{Meta} ++ InputComponentTypes;
        const ComponentsPointers = [Components.len][*]u8;

        const MaxAlign = value: {
            var maxAlign = 0;

            for (Components) |t| {
                const a = @alignOf(t);

                if (a > maxAlign) {
                    maxAlign = a;
                }
            }

            break :value maxAlign;
        };

        alloc: std.mem.Allocator,
        components: ComponentsPointers,
        len: u32,
        capacity: u32,
        generation: u32,
        free_head: u32,

        pub fn init(capacity: u32, alloc: std.mem.Allocator) !Self {
            var components: ComponentsPointers = undefined;

            inline for (Components) |T, idx| {
                if (@sizeOf(T) == 0) continue;

                const slice = try alloc.alloc(T, capacity);
                components[idx] = @ptrCast([*]u8, slice.ptr);
            }

            return Self{
                .components = components,
                .len = 0,
                .generation = 1,
                .capacity = capacity,
                .alloc = alloc,
                .free_head = std.math.maxInt(u32),
            };
        }

        pub fn deinit(self: *Self) void {
            inline for (Components) |T, idx| {
                if (@sizeOf(T) == 0) continue;

                var slice: []T = &.{};
                slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.components[idx]));
                slice.len = self.capacity;

                self.alloc.free(slice);
            }
        }

        pub fn create(self: *Self, name: []const u8) !EntityId {
            const index = index: {
                if (self.free_head != std.math.maxInt(u32)) {
                    const index = self.free_head;
                    const meta = &self.raw(Meta)[self.free_head];
                    self.free_head = @truncate(u32, meta.name.len);

                    break :index index;
                }

                if (self.len >= self.capacity) {
                    const new_capa = self.capacity + self.capacity / 2;

                    inline for (Components) |T, idx| {
                        if (@sizeOf(T) == 0) continue;

                        var slice: []T = &.{};
                        slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.components[idx]));
                        slice.len = self.capacity;

                        const new_mem = try self.alloc.realloc(slice, new_capa);
                        self.components[idx] = @ptrCast([*]u8, new_mem.ptr);
                    }

                    self.capacity = new_capa;
                }

                const index = self.len;
                self.len += 1;
                break :index index;
            };

            const meta = &self.raw(Meta)[index];
            meta.name = name;
            meta.generation = self.generation;
            meta.bitset = std.StaticBitSet(Components.len).initEmpty();

            return EntityId{ .index = index, .generation = self.generation };
        }

        pub fn delete(self: *Self, id: EntityId) bool {
            const index = self.indexOf(id) orelse return false;
            const meta = &self.raw(Meta)[index];

            meta.generation = std.math.maxInt(u32);
            meta.name = "";
            meta.name.len = self.free_head;

            self.free_head = id.index;
            self.generation += 1;

            return true;
        }

        pub fn addComponent(self: *Self, id: EntityId, component: anytype) bool {
            const index = self.indexOf(id) orelse return false;

            const T = @TypeOf(component);

            self.raw(Meta)[index].bitset.set(typeIndex(T));
            const elements = self.raw(T);
            elements[index] = component;

            return true;
        }

        pub fn raw(self: *Self, comptime T: type) []T {
            const index = typeIndex(T);

            var slice: []T = &.{};
            slice.len = self.len;

            if (@sizeOf(T) > 0) {
                slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.components[index]));
            }

            return slice;
        }

        pub fn view(self: *Self, comptime ViewType: type) RegistryView(Self, ViewType) {
            return .{ .registry = self };
        }

        fn indexOf(self: *Self, id: EntityId) ?u32 {
            const meta_slice = self.raw(Meta);
            if (id.index >= meta_slice.len) return null;

            const meta = &meta_slice[id.index];
            if (meta.generation > id.generation) return null;

            return id.index;
        }

        fn typeIndex(comptime T: type) usize {
            comptime {
                for (Components) |Component, idx| {
                    if (T == Component) return idx;
                }

                @compileError("Type not registered: " ++ @typeName(T));
            }
        }
    };
}

test "Registry: iterate" {
    const TransformComponent = struct { i: u32 };
    const MoveComponent = struct {};

    const Registry = NewRegistryType(&.{ TransformComponent, MoveComponent });

    var registry = try Registry.init(256, liu.Pages);
    defer registry.deinit();

    var success = false;

    var i: u32 = 0;
    while (i < 257) : (i += 1) {
        const meh = try registry.create("meh");
        success = registry.addComponent(meh, TransformComponent{ .i = meh.index });
        try std.testing.expect(success);
    }

    try std.testing.expect(registry.len == 257);
    try std.testing.expect(registry.capacity > 256);

    const View = struct {
        transform: ?TransformComponent,
        move: ?*MoveComponent,
    };

    var view = registry.view(View);
    while (view.next()) |elem| {
        try std.testing.expect(elem.meta.name.len == 3);
        if (elem.transform) |t|
            try std.testing.expect(t.i == elem.id)
        else
            try std.testing.expect(false);

        try std.testing.expect(elem.move == null);
    }

    _ = registry.raw(TransformComponent);
}

test "Registry: delete" {
    const TransformComponent = struct {};
    const MoveComponent = struct {};

    const Registry = NewRegistryType(&.{ TransformComponent, MoveComponent });

    var registry = try Registry.init(256, liu.Pages);
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
        try std.testing.expect(elem.meta.name.len == 3);
        count += 1;
    }

    try std.testing.expect(count == 1);

    _ = registry.raw(TransformComponent);
}
