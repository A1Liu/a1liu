const std = @import("std");
const mem = std.mem;
const trait = std.meta.trait;

const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// inspiration (and some copying) from https://github.com/alexnask/interface.zig
// https://stackoverflow.com/questions/61466724/generation-of-types-in-zig-zig-language
//
// Not really possible without a large number of hacks right now.
// Requires: https://github.com/ziglang/zig/issues/6709

