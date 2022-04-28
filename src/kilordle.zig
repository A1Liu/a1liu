const std = @import("std");
const assets = @import("assets");
const liu = @import("liu");

const wasm = liu.wasm;
usingnamespace wasm;

export fn add(a: u32, b: u32) u32 {
    std.log.info("Hello!", .{});

    return a + b;
}
