const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

// https://youtu.be/SFKR5rZBu-8?t=2202

// use bitset for whether a component exists

pub const EntityId = struct {
    index: u32,
    generation: u32,
};

const Vector3 = @Vector(3, f32);
const Vector4 = @Vector(4, f32);

fn RegistryView(comptime Registry: type, comptime InViewType: type) type {
    return struct {
        // We always add the meta component
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

        pub inline fn next(self: *Iter) ?ViewType {
            if (self.index >= self.registry.len) {
                return null;
            }

            const meta = &self.registry.raw(Registry.Meta)[self.index];

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

                    const index = Registry.typeIndex(T);
                    if (!meta.bitset.isSet(index)) {
                        break :value null;
                    }

                    const ptr = &self.registry.raw(T)[self.index];
                    break :value if (isPointer) ptr else ptr.*;
                };
            }

            self.index +|= 1;

            return value;
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
            name: []const u8,
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

        pub fn init(capacity: u32, alloc: std.mem.Allocator) !Self {
            var components: ComponentsPointers = undefined;

            inline for (Components) |T, idx| {
                const slice = try alloc.alloc(T, capacity);
                components[idx] = @ptrCast([*]u8, slice.ptr);
            }

            return Self{
                .components = components,
                .len = 0,
                .generation = 0,
                .capacity = capacity,
                .alloc = alloc,
            };
        }

        pub fn deinit(self: *Self) void {
            inline for (Components) |T, idx| {
                var slice: []T = &.{};
                slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.components[idx]));
                slice.len = self.capacity;

                self.alloc.free(slice);
            }
        }

        pub fn create(self: *Self, name: []const u8) !EntityId {
            const index = self.len;
            self.len += 1;

            const entity_meta = &self.raw(Meta)[index];
            entity_meta.name = name;
            entity_meta.generation = self.generation;
            entity_meta.bitset = std.StaticBitSet(Components.len).initEmpty();

            return EntityId{ .index = index, .generation = self.generation };
        }

        pub fn meta(self: *Self) []Meta {
            return self.raw(Meta);
        }

        fn typeIndex(comptime T: type) usize {
            comptime {
                for (Components) |Component, idx| {
                    if (T == Component) return idx;
                }

                @compileError("Type not registered: " ++ @typeName(T));
            }
        }

        pub fn raw(self: *Self, comptime T: type) []T {
            const index = typeIndex(T);

            var slice: []T = &.{};
            slice.ptr = @ptrCast([*]T, @alignCast(@alignOf(T), self.components[index]));
            slice.len = self.len;

            return slice;
        }

        pub fn view(self: *Self, comptime ViewType: type) RegistryView(Self, ViewType) {
            return .{ .registry = self };
        }
    };
}

const TransformComponent = struct {
    position: Vector3,
    rotation: Vector4,
    scale: f32,
};

const MoveComponent = struct {
    direction: Vector3, // normalized
    speed: f32,
};

const EffectComponent = struct {
    applied_to: EntityId,
    tied_to: EntityId,
};

const DecisionComponent = union(enum) {
    player: void,
};

test "Registry: iterate" {
    const Registry = NewRegistryType(&.{ TransformComponent, MoveComponent });

    var registry = try Registry.init(256, liu.Pages);
    defer registry.deinit();

    const View = struct {
        transform: ?TransformComponent,
        move: ?*MoveComponent,
    };

    _ = try registry.create("meh");

    var iter = registry.view(View);
    while (iter.next()) |view| {
        try std.testing.expect(view.meta.name.len == 3);
    }

    _ = registry.raw(TransformComponent);
}
