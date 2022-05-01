const std = @import("std");
const liu = @import("liu");
const kilo = @import("./kilordle.zig");

pub fn main() void {
    kilo.init();

    _ = kilo.submitWord('H', 'E', 'L', 'L', 'O');
    _ = kilo.submitWord('W', 'O', 'R', 'D', 'S');
}
