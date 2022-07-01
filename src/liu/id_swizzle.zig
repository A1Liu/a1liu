const std = @import("std");

fn idMask(comptime T: type) T {
    return switch (T) {
        u32 => 0b10100110_01101010_01001010_10101010,
        u64 => 0b10100110_01101010_01001010_10101010_10100110_01101010_01001010_10101010,

        else => @compileError("the type '" ++ @typeName(T) ++ "' doesn't work as an ID type"),
    };
}

fn idAdd(comptime T: type) T {
    return switch (T) {
        u32 => 2740160927,
        u64 => 10063238043947838519,

        else => @compileError("the type '" ++ @typeName(T) ++ "' doesn't work as an ID type"),
    };
}

fn IdMul(comptime T: type) type {
    return struct {
        to: T,
        from: T,
    };
}

// 16294208416658607535 817831822087661903
// 10451216379200822465 10888168410540946241
// 11317887983584761797 11674727387005193997

// These two numbers are multiplicative inverses mod T
fn idMul(comptime T: type) IdMul(T) {
    return switch (T) {
        u32 => .{ .to = 0x01000193, .from = 0x359c449b },
        u64 => .{ .to = 16294208416658607535, .from = 817831822087661903 },

        else => @compileError("the type '" ++ @typeName(T) ++ "' doesn't work as an ID type"),
    };
}

// const ID_ROTATE_BITS: u32 = 16;
// let s2 = s1.swap_bytes();
// let s5 = s4.rotate_left(ID_ROTATE_BITS);

pub fn SwizzledId(comptime T: type) type {
    return enum(T) {
        _,

        const ADD = idAdd(T);
        const MASK = idMask(T);
        const MUL = idMul(T);

        const Self = @This();

        pub inline fn fromRaw(val: T) Self {
            return @intToEnum(Self, val);
        }

        pub inline fn raw(self: Self) T {
            return @enumToInt(self);
        }

        pub fn fromSwizzle(val: T) Self {
            const s1 = val ^ MASK;
            const s2 = s1 *% MUL.to;
            const s3 = s2 -% ADD;

            return @intToEnum(Self, s3);
        }

        pub fn swizzle(self: Self) T {
            const s3 = @enumToInt(self) +% ADD;
            const s2 = s3 *% MUL.from;
            const s1 = s2 ^ MASK;

            return s1;
        }
    };
}

pub fn testData(comptime T: type) !void {
    const Id = SwizzledId(T);

    try std.testing.expectEqual(Id.MUL.to *% Id.MUL.from, 1);

    const tests = [_]T{ Id.MASK, Id.ADD, Id.MUL.to, Id.MUL.from };

    {
        var id: T = 0;
        while (id < 100) : (id += 1) {
            const value = Id.fromSwizzle(id);
            const out_id = value.swizzle();

            // println!("{} -> {}", id, value);

            // println!("{:>10}", value);

            try std.testing.expectEqual(id, out_id);
        }
    }

    for (tests) |id| {
        const value = Id.fromSwizzle(id);
        const out_id = value.swizzle();

        // println!("{} -> {}", id, value);

        try std.testing.expectEqual(id, out_id);
    }

    var value: T = 0;
    while (value < 100) : (value += 100) {
        const id = Id.fromSwizzle(value);
        const out_value = id.swizzle();

        // println!("{} -> {}", id, value);

        try std.testing.expectEqual(value, out_value);
    }

    try std.testing.expectEqual(Id.fromSwizzle(0).raw(), std.math.maxInt(T));
}

test "Id swizzle: basic" {
    try testData(u32);
    try testData(u64);
}
