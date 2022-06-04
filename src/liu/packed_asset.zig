const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const native_endian = builtin.target.cpu.arch.endian();
pub fn read(bytes: []const u8, comptime T: type) ?T {
    const Size = @sizeOf(T);

    if (bytes.len < Size) return null;

    switch (@typeInfo(T)) {
        .Int => {
            var value: T = @bitCast(T, bytes[0..Size].*);
            if (native_endian != .Big) value = @byteSwap(T, value);

            return value;
        },

        else => @compileError("input type is not allowed (only allows integers right now)"),
    }
}

pub fn U32Slice(comptime T: type) type {
    return extern struct {
        word_offset: u32,
        length: u32,

        pub const T = T;
    };
}

// struct fields need to be sorted by alignment

// pass in Type
// Type must be extern struct, integer, float, or u32_slice
// Child types must also obey above rule
// Accesses are bounds-checked
// Data is in-place mutated

// Does not track memory safety, but all offsets are positive, so you at
// least can't have cycles.

pub fn encode(alloc: std.Allocator, value: anytype) ?[]u8 {
    _ = alloc;
    _ = value;

    return null;
}

pub fn parse(comptime T: type, bytes: []align(8) u8) ?T {
    _ = T;
    _ = bytes;

    return null;
}
