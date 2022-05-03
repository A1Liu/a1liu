const std = @import("std");
const liu = @import("liu");

const WordArray = packed struct {
    a1: u6,
    a2_1: u2,
    a2_2: u4,
    a3_1: u4,
    a3_2: u2,
    a4: u6,
    a5: u6,
};

pub fn main() !void {
    std.debug.print("{}\n", .{@sizeOf(WordArray)});
}
