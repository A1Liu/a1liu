const std = @import("std");

const ID_MASK: u32 = 0b10100110_01101010_01001010_10101010;
const ID_ADD: u32 = 2740160927;

// These two numbers are multiplicative inverses mod 2^32
const ID_MUL_TO: u32 = 0x01000193;
const ID_MUL_FROM: u32 = 0x359c449b;

// const ID_ROTATE_BITS: u32 = 16;
// let s2 = s1.swap_bytes();
// let s5 = s4.rotate_left(ID_ROTATE_BITS);

pub fn Id(comptime T: type) type {
    return enum(T) {
        _,

        const Self = @This();

        pub inline fn fromIndex(val: T) Self {
            return @intToEnum(Self, val);
        }

        pub inline fn index(self: Self) T {
            return @enumToInt(self);
        }

        pub inline fn fromSwizzle(val: T) Self {
            const s3 = val +% ID_ADD;
            const s2 = s3 *% ID_MUL_FROM;
            const s1 = s2 ^ ID_MASK;

            return @intToEnum(Self, s1);
        }

        pub fn swizzle(self: Self) T {
            const s1 = @enumToInt(self) ^ ID_MASK;
            const s2 = s1 *% ID_MUL_TO;
            const s3 = s2 -% ID_ADD;

            return s3;
        }
    };
}

test "Id swizzle: basic" {
    try std.testing.expectEqual(ID_MUL_TO *% ID_MUL_FROM, 1);

    const tests = [_]u32{ ID_MASK, ID_ADD, ID_MUL_TO, ID_MUL_FROM };

    {
        var id: u32 = 0;
        while (id < 100) : (id += 1) {
            const value = Id(u32).fromSwizzle(id);
            const out_id = value.swizzle();

            // println!("{} -> {}", id, value);

            // println!("{:>10}", value);

            try std.testing.expectEqual(id, out_id);
        }
    }

    for (tests) |id| {
        const value = Id(u32).fromSwizzle(id);
        const out_id = value.swizzle();

        // println!("{} -> {}", id, value);

        try std.testing.expectEqual(id, out_id);
    }

    var value: u32 = 0;
    while (value < 100) : (value += 100) {
        const id = Id(u32).fromSwizzle(value);
        const out_value = id.swizzle();

        // println!("{} -> {}", id, value);

        try std.testing.expectEqual(value, out_value);
    }
}
