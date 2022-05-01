const std = @import("std");
const liu = @import("liu");
const kilo = @import("./kilordle.zig");

pub fn main() !void {
    try kilo.init();

    _ = try kilo.submitWord("HELLO".*);
    _ = try kilo.submitWord("WORDS".*);
}
