const alloc = @import("./allocators.zig");
const buffers = @import("./buffers.zig");
const math = @import("./math.zig");
const interface = @import("./interface.zig");
const ecs = @import("./ecs.zig");

pub const packed_asset = @import("./packed_asset.zig");

pub const fonts = @import("./fonts.zig");
pub const sdf = @import("./sdf.zig");
pub const img = @import("./img.zig");

pub const wasm = @import("wasm.zig");

pub usingnamespace alloc;
pub usingnamespace buffers;
pub usingnamespace math;
pub usingnamespace interface;
pub usingnamespace ecs;

// NOTE: this forces the compiler to run the tests in the listed folders when
// running `zig test src/liu/lib.zig
test {
    _ = fonts;
    _ = sdf;
    _ = img;
    _ = packed_asset;
}
