const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const HiddenDummy: u8 = 0;

pub fn U32Slice(comptime T: type) type {
    return extern struct {
        word_offset: u32,
        len: u32,

        pub const SliceType = T;
        const LiuPackedAssetDummyField: *const u8 = &HiddenDummy;
    };
}

const Version: u32 = 0;
const Spec = enum(u8) {
    pu8,
    pu16,
    pu32,
    pu64,

    pi8,
    pi16,
    pi32,
    pi64,

    pf32,
    pf64,

    uslice_of_next, // align 4, size 8

    // align 8; this could be lower, but the idea is that you only pay the
    // padding cost once per-allocation, and that this ultimately is a rare
    // occurence.
    ustruct_open,
    ustruct_close,
};

const native_endian = builtin.target.cpu.arch.endian();
fn specFromType(comptime T: type) []const Spec {
    if (native_endian != .Little)
        @compileError("target platform must be little endian");

    if (@sizeOf(T) == 0)
        @compileError("type has size of 0, what would you even store in the asset file?");
    if (@alignOf(T) > 8)
        @compileError("maximum alignment for values is 8");

    comptime {
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
                if (info.layout != .Extern)
                    @compileError("struct must be laid out using extern format");

                if (@hasDecl(T, "LiuPackedAssetDummyField")) {
                    if (T.LiuPackedAssetDummyField == &HiddenDummy) {
                        return &[_]Spec{.uslice_of_next} ++ specFromType(T.SliceType);
                    }
                }

                var spec: []const Spec = &[_]Spec{.ustruct_open};
                for (info.fields) |field| {
                    spec = spec ++ specFromType(field.field_type);
                }

                return spec ++ &[_]Spec{.ustruct_close};
            },

            .Pointer => @compileError("Native pointers are unsupported. " ++
                "If you're looking for slices, use the custom wrapper type instead"),

            else => @compileError("Unsupported type: " ++ @typeName(T)),
        }
    }
}

// pass in Type
// Type must be extern struct, integer, float, or u32_slice
// Child types must also obey above rule
// Accesses are bounds-checked
// Asset data is in-place mutated
// maximum alignment is 8

// Require platform to be little-endian

// Does not track memory safety, but all offsets are positive, so you at
// least can't have cycles.

// Algorithm generates spec array first, which is what gets stored; then other algo
// reads from spec array and does decisions.
//
// Spec generation implicitly excludes recursive types at compile time. This
// makes things easier, but maybe is bad for usability. For sure, the compile
// error is atrocious.

const Encoder = struct {
    spec: []const Spec,
    index: u32 = 0,

    fn encode(self: *@This(), chunk: []align(8) u8) void {
        if (self.index == 0) {
            // output header:
            // magic number: aliu
            // version number
            // spec end
            // spec array
        }

        _ = chunk;
    }
};

const DefaultChunkSize = 16 * 4096;
pub fn tempEncode(value: anytype, comptime chunk_size_: ?u32) ![]*align(8) [chunk_size_ orelse DefaultChunkSize]u8 {
    const chunk_size = chunk_size_ orelse DefaultChunkSize;
    if (comptime chunk_size % 8 != 0) {
        @compileError("chunk size must be aligned to 8 bytes");
    }

    const ChunkT = [chunk_size]u8;
    const ChunkPtrT = *align(8) ChunkT;

    var encoder = Encoder{ .spec = specFromType(@TypeOf(value)) };
    var list = std.ArrayList(ChunkPtrT).init(liu.Temp);

    var chunk = &(try liu.Temp.alignedAlloc(ChunkT, 8, 1))[0];

    _ = encoder;
    _ = chunk;
    _ = list;
    _ = value;

    return list.items;
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

    const a: u8 = 12;
    _ = try tempEncode(a, null);
}
