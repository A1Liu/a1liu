const std = @import("std");
const liu = @import("liu");

// https://youtu.be/SFKR5rZBu-8?t=2202

// use bitset for whether a component exists

const EntityId = u64;

const Vector3 = @Vector(3, f32);
const Vector4 = @Vector(4, f32);

pub fn NewRegistryType(comptime ComponentTypes: []const type) type {
    // comptime {
    //     for (ComponentTypes) |t, idx| {
    //         for (ComponentTypes[0..idx]) |prev| {
    //             if (prev == t) std.debug.assert(false);
    //         }
    //     }
    // }

    return struct {
        const MetaComponent = struct {
            name: []const u8,
            generation: u32,
            bitset: std.IntegerBitSet(std.math.cast(u16, ComponentTypes.len)),
        };

        const Self = @This();

        const MaxAlign = value: {
            var maxAlign = 0;
            for (ComponentTypes) |t| {
                const a = @alignOf(t);
                if (a > maxAlign) {
                    maxAlign = a;
                }
            }

            break :value maxAlign;
        };

        components: [ComponentTypes.len + 1][*]align(MaxAlign) u8,

        pub fn init() Self {
            return .{};
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

test "Registry: build" {
    const Registry = NewRegistryType(&.{ TransformComponent, MoveComponent });
    _ = Registry;
}
