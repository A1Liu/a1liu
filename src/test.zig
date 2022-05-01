const std = @import("std");
const liu = @import("liu");
const kilo = @import("./kilordle.zig");

pub fn main() void {
    kilo.init();

    kilo.submitWord('H', 'E', 'L', 'L', 'O');
    kilo.submitWord('W', 'O', 'R', 'D', 'S');
}
