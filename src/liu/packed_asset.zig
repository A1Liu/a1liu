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

const HiddenDummy: u8 = 0;

pub fn U32Slice(comptime T: type) type {
    return extern struct {
        word_offset: u32,
        length: u32,

        pub const SliceType = T;
        const LiuPackedAssetDummyField: *const u8 = &HiddenDummy;
    };
}

const Spec = enum(u8) {
    pu8,
    // pi8,
    // pu32,
    // pi32,
    // pu64,
    // pi64,

    // pf32,
    // pf64,

    uslice_of_next, // align 4, size 8

    ustruct_open,
    ustruct_close,
};

fn specFromType(comptime T: type) []const Spec {
    comptime {
        if (@sizeOf(T) == 0) @compileError("type has size of 0, what would you even store in the asset file?");

        switch (@typeInfo(T)) {
            .Int => |info| {
                if (info.signedness == .signed or info.bits != 8)
                    @compileError("only handles u8 right now");

                return &.{.pu8};
            },

            .Struct => |info| {
                // There's an argument you could make that this should actually
                // accept only packed and not extern. Extern is easier to
                // implement.
                //                      - Albert Liu, Jun 04, 2022 Sat 14:48 PDT
                if (info.layout != .Extern) @compileError("struct must be laid out using extern format");

                if (@hasDecl(T, "LiuPackedAssetDummyField")) {
                    if (T.LiuPackedAssetDummyField == &HiddenDummy) {
                        return &[_]Spec{.uslice_of_next} ++ specFromType(T.SliceType);
                    }
                }

                var spec: []const Spec = &[_]Spec{.ustruct_open};
                var alignment: u32 = std.math.maxInt(u32);
                var max_align: u32 = 0;
                for (info.fields) |field| {
                    const new_align = @alignOf(field.field_type);
                    if (new_align > alignment) {
                        @compileError("Fields must be sorted in order of alignment, highest first");
                    }

                    alignment = new_align;
                    max_align = std.math.max(max_align, new_align);

                    spec = spec ++ specFromType(field.field_type);
                }

                return spec ++ &[_]Spec{.ustruct_close};
            },

            .Pointer => @compileError("Native pointers are unsupported. " ++
                "Use the custom wrapper type instead"),

            else => {
                @compileError("Unsupported type: " ++ @typeName(T));
            },
        }
    }
}

// struct fields need to be sorted by alignment

// pass in Type
// Type must be extern struct, integer, float, or u32_slice
// Child types must also obey above rule
// Accesses are bounds-checked
// Asset data is in-place mutated

// Does not track memory safety, but all offsets are positive, so you at
// least can't have cycles.

// Algorithm generates spec array first, which is what gets stored; then other algo
// reads from spec array and does decisions.
//
// Spec generation implicitly excludes recursive types at compile time. This
// makes things easier, but maybe is bad for usability. For sure, the compile
// error is atrocious.

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

test "Packed Asset: spec generation" {
    const Test = extern struct {
        data: U32Slice(u8),
        field: u8,
    };

    const spec = specFromType(Test);

    try std.testing.expect(std.mem.eql(Spec, spec, &.{
        .ustruct_open,
        .uslice_of_next,
        .pu8,
        .pu8,
        .ustruct_close,
    }));
}
