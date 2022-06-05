//! Packed asset format. Poorly suited for highly-nested data, or data whose
//! schema changes often. Doesn't handle very many types, as the intention
//! is to store Plain-old-data, and not anything crazier than that.
//!
//! Stores the type of of the assets in the file, and checks that the stored
//! type and the requested type are the same before continuing.
//!
//! Passed-in type and all its child types must obey the following rules:
//! - must be struct, integer, float, or slice
//! - must have a maximum alignment of 8
//! - must not be recursive.
//!
//! Only supports little-endian platforms
//!
//! Does not track memory safety, but all offsets are positive, so you at
//! least can't have cycles.

// Algorithm generates spec array first, which is what gets stored; then other algo
// reads from spec array and does decisions.
//
// Spec generation implicitly excludes recursive types at compile time. This
// makes things easier, but maybe is bad for usability. For sure, the compile
// error is atrocious.

const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const SliceMarker: u8 = 0;
pub fn U32Slice(comptime T: type) type {
    return extern struct {
        word_offset: u32,
        len: u32,

        pub const SliceType = T;
        const LiuPackedAssetDummyField: *const u8 = &SliceMarker;

        pub fn slice(self: *@This()) []T {
            const address = @ptrToInt(self);

            var out: []T = &.{};
            out.ptr = @intToPtr([*]T, 4 * self.word_offset + address + 8);
            out.len = self.len;

            return out;
        }
    };
}

const Version: u32 = 0;

const native_endian = builtin.target.cpu.arch.endian();

pub const Spec = struct {
    Type: type,
    Info: []const Info,
    EncodeInfo: []const EncodeInfo,

    pub const Info = enum(u8) {
        // zig fmt: off
        pu8, pu16, pu32, pu64,
        pi8, pi16, pi32, pi64,
        pf32, pf64,

        uslice_of_next, // align 4, size 8

        ustruct_open_1, ustruct_open_2, ustruct_open_4, ustruct_open_8,
        ustruct_close,
        _,
        // zig fmt: on

        fn pSize(self: @This()) ?u8 {
            return switch (self) {
                .pu8, .pi8 => 1,
                .pu16, .pi16 => 2,
                .pu32, .pi32, .pf32 => 4,
                .pu64, .pi64, .pf64 => 8,

                else => null,
            };
        }

        fn alignment(self: @This()) u16 {
            return switch (self) {
                .pu8, .pi8 => 1,
                .pu16, .pi16 => 2,
                .pu32, .pi32, .pf32 => 4,
                .pu64, .pi64, .pf64 => 8,

                .uslice_of_next => 4,

                .ustruct_open_1 => 1,
                .ustruct_open_2 => 2,
                .ustruct_open_4 => 4,
                .ustruct_open_8 => 8,

                .ustruct_close => 0,

                else => 0,
            };
        }
    };

    pub const EncodeInfo = struct {
        type_info: Info,
        field_offset: u32 = 0, // ignored when it doesn't apply
    };

    pub fn fromType(comptime T: type) @This() {
        if (native_endian != .Little)
            @compileError("target platform must be little endian");

        comptime {
            const ExternType = translateType(T);

            const encode_info = makeInfo(ExternType, T);
            var info: []const Info = &.{};
            for (encode_info) |e| {
                info = info ++ &[_]Info{e.type_info};
            }

            return .{ .Type = ExternType, .EncodeInfo = encode_info, .Info = info };
        }
    }

    pub fn decodeInfo(comptime T: type) []const Info {
        const encode_info = makeInfo(T, null);
        var info: []const Info = &.{};
        for (encode_info) |e| {
            info = info ++ &.{e.type_info};
        }

        return info;
    }

    fn isInternalSlice(comptime T: type) bool {
        comptime {
            return @typeInfo(T) == .Struct and @hasDecl(T, "LiuPackedAssetDummyField") and
                T.LiuPackedAssetDummyField == &SliceMarker;
        }
    }

    fn makeInfo(comptime Extern: type, comptime Base: ?type) []const EncodeInfo {
        if (native_endian != .Little)
            @compileError("target platform must be little endian");

        if (@sizeOf(Extern) == 0)
            @compileError("type has size of 0, what would you even store in the asset file?");
        if (@alignOf(Extern) > 8)
            @compileError("maximum alignment for values is 8");
        if (@alignOf(Extern) == 0)
            @compileError("what does align=0 even mean");

        comptime {
            switch (@typeInfo(Extern)) {
                .Int => |info| {
                    const type_info: Spec.Info = switch (info.bits) {
                        8 => if (info.signedness == .signed) .pi8 else .pu8,
                        16 => if (info.signedness == .signed) .pi16 else .pu16,
                        32 => if (info.signedness == .signed) .pi32 else .pu32,
                        64 => if (info.signedness == .signed) .pi64 else .pu64,
                        else => @compileError("doesn't handle non-standard integer sizes"),
                    };

                    return &.{EncodeInfo{ .type_info = type_info }};
                },

                .Struct => |info| {
                    // There's an argument you could make that this should actually
                    // accept only packed and not extern. Extern is easier to
                    // implement.
                    //                      - Albert Liu, Jun 04, 2022 Sat 14:48 PDT
                    if (info.layout != .Extern)
                        @compileError("struct must be laid out using extern format");

                    if (isInternalSlice(Extern)) {
                        const ElemBase = if (Base) |B| b: {
                            break :b if (isInternalSlice(B)) null else std.meta.Child(B);
                        } else null;
                        const elem_type = makeInfo(Extern.SliceType, ElemBase);
                        const slice_info = Spec.EncodeInfo{
                            .type_info = .uslice_of_next,
                        };

                        return &[_]EncodeInfo{slice_info} ++ elem_type;
                    }

                    const spec_info: Spec.Info = switch (@alignOf(Extern)) {
                        1 => .ustruct_open_1,
                        2 => .ustruct_open_2,
                        4 => .ustruct_open_4,
                        8 => .ustruct_open_8,
                        else => unreachable,
                    };

                    const val = EncodeInfo{ .type_info = spec_info };

                    var spec: []const Spec.EncodeInfo = &[_]EncodeInfo{val};

                    if (Base) |B| {
                        var b: B = undefined;

                        for (info.fields) |field| {
                            const encode_info = makeInfo(
                                field.field_type,
                                @TypeOf(@field(b, field.name)),
                            );

                            for (encode_info) |e| {
                                const offset = e.field_offset;
                                const new_info = EncodeInfo{
                                    .type_info = e.type_info,
                                    .field_offset = offset + @offsetOf(B, field.name),
                                };

                                spec = spec ++ &[_]EncodeInfo{new_info};
                            }
                        }
                    } else {
                        for (info.fields) |field| {
                            spec = spec ++ makeInfo(field.field_type, null);
                        }
                    }

                    return spec ++ &[_]Spec.EncodeInfo{.{ .type_info = .ustruct_close }};
                },

                .Pointer => @compileError("Native pointers are unsupported. " ++
                    "If you're looking for slices, use the custom wrapper type instead"),

                else => @compileError("Unsupported type: " ++ @typeName(Extern)),
            }
        }
    }

    fn translateType(comptime T: type) type {
        const StructField = std.builtin.Type.StructField;

        comptime {
            const info = switch (@typeInfo(T)) {
                .Int => return T,
                .Float => return T,

                .Struct => |info| info,

                .Pointer => |info| {
                    if (info.size == .Slice) {
                        return U32Slice(translateType(info.child));
                    }

                    @compileError("only slices allowed right now");
                },

                else => @compileError("type is not compatible with serialization"),
            };

            if (isInternalSlice(T)) {
                return T;
            }

            var translated: []const StructField = &.{};

            var no_change = true;
            for (info.fields) |field| {
                const FieldT = translateType(field.field_type);
                if (FieldT != field.field_type) no_change = false;

                const to_add = StructField{
                    .name = field.name,
                    .field_type = FieldT,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(FieldT),
                };

                translated = translated ++ &[_]StructField{to_add};
            }

            if (info.layout == .Extern) {
                if (no_change) {
                    return T;
                }

                return @Type(.{
                    .Struct = .{
                        .layout = .Extern,
                        .decls = &.{},
                        .is_tuple = false,
                        .fields = translated,
                    },
                });
            }

            var fields: []const StructField = &.{};

            // We allow the extern code below to validate alignment, here
            // we simply sort the fields by alignment.
            for (translated) |field| {
                if (field.alignment >= 8) {
                    fields = fields ++ &[_]StructField{field};
                }
            }

            for (translated) |field| {
                if (field.alignment == 4) {
                    fields = fields ++ &[_]StructField{field};
                }
            }

            for (translated) |field| {
                if (field.alignment == 2) {
                    fields = fields ++ &[_]StructField{field};
                }
            }

            for (translated) |field| {
                if (field.alignment <= 1) {
                    fields = fields ++ &[_]StructField{field};
                }
            }

            return @Type(.{
                .Struct = .{
                    .layout = .Extern,
                    .decls = &.{},
                    .is_tuple = false,
                    .fields = fields,
                },
            });
        }
    }
};

const Header = extern struct {
    magic: [4]u8 = "aliu"[0..4].*,
    version: u32 = Version,
    data_begin: u32,
    spec_len: u32,
};

const Encoder = struct {
    file_offset: u32 = 0,

    // const ObjectEncoder = struct {
    spec: []const Spec.EncodeInfo,
    spec_index: u32 = 0,
    object: [*]const u8,
    object_base: u32 = 0,
    object_len: u32,
    // };

    const Result = union(enum) {
        done: u32,
        not_done: void,
    };

    fn init(comptime T: type, value: *const T) @This() {
        return .{
            .spec = Spec.fromType(T).EncodeInfo,
            .object = @ptrCast([*]const u8, value),
            .object_len = @sizeOf(T),
        };
    }

    fn encode(self: *@This(), chunk: []align(8) u8) Result {
        std.debug.assert(chunk.len % 8 == 0);

        const len = @truncate(u32, chunk.len);

        var cursor: u32 = 0;
        defer self.file_offset += len;

        if (self.file_offset == 0) { // output header:
            // TODO: Ensure that the chunk is large enough to output the header.

            // magic number: aliu
            chunk[0..4].* = "aliu"[0..4].*;

            // version number
            chunk[4..8].* = @bitCast([4]u8, Version);

            // data begin
            const spec_len = @truncate(u32, self.spec.len);
            const data_begin = @truncate(u32, std.mem.alignForward(16 + spec_len, 8));
            chunk[8..12].* = @bitCast([4]u8, data_begin);

            // spec len
            chunk[12..16].* = @bitCast([4]u8, spec_len);

            // spec array
            for (self.spec) |s, i| {
                chunk[i + 16] = @enumToInt(s.type_info);
            }

            std.mem.set(u8, chunk[(16 + spec_len)..data_begin], 0);

            cursor = data_begin;
            self.object_base = data_begin;
        }

        while (self.spec_index < self.spec.len) : (self.spec_index += 1) {
            const s = self.spec[self.spec_index];

            if (s.type_info == .ustruct_close) {
                continue;
            }

            const alignment = s.type_info.alignment();
            const aligned_cursor = @truncate(u32, std.mem.alignForward(cursor, alignment));

            // fill padding with zeroes
            std.mem.set(u8, chunk[cursor..aligned_cursor], 0);

            cursor = aligned_cursor;

            const field_mem = self.object + s.field_offset;
            if (s.type_info.pSize()) |size| {
                if (cursor + size > len) {
                    return .not_done;
                }

                switch (size) {
                    1 => chunk[cursor..][0..1].* = field_mem[0..1].*,
                    2 => chunk[cursor..][0..2].* = field_mem[0..2].*,
                    4 => chunk[cursor..][0..4].* = field_mem[0..4].*,
                    8 => chunk[cursor..][0..8].* = field_mem[0..8].*,
                    else => {
                        unreachable;
                    },
                }

                cursor += size;
                continue;
            }

            switch (s.type_info) {
                .uslice_of_next => {
                    if (cursor + 8 > len) {
                        return .not_done;
                    }

                    // TODO: slices
                },

                // struct_open doesn't have any data
                else => continue,
            }
        }

        return .{ .done = cursor };
    }
};

fn Encoded(comptime chunk_size: u32) type {
    return struct {
        chunks: []*align(8) [chunk_size]u8,
        last: []align(8) const u8,

        pub const ChunkSize = chunk_size;

        pub fn len(self: *const @This()) usize {
            return self.chunks.len * chunk_size + self.last.len;
        }

        pub fn copyContiguous(self: *const @This(), alloc: std.mem.Allocator) ![]align(8) u8 {
            const bytes = try alloc.alignedAlloc(u8, 8, self.len());
            for (self.chunks) |chunk, i| {
                const begin = i * ChunkSize;
                std.mem.copy(u8, bytes[begin..], chunk);
            }

            {
                const begin = self.chunks.len * ChunkSize;
                std.mem.copy(u8, bytes[begin..], self.last);
            }

            return bytes;
        }
    };
}

const DefaultChunkSize = 16 * 4096;
pub fn tempEncode(value: anytype, comptime chunk_size_: ?u32) !Encoded(chunk_size_ orelse DefaultChunkSize) {
    const chunk_size = chunk_size_ orelse DefaultChunkSize;
    if (comptime chunk_size % 8 != 0)
        @compileError("chunk size must be aligned to 8 bytes");

    const spec = Spec.fromType(@TypeOf(value));
    if (comptime chunk_size < std.mem.alignForward(spec.Info.len + 16, 8))
        @compileError("chunk size should be at least enough bytes to hold the header");

    const ChunkT = [chunk_size]u8;
    const ChunkPtrT = *align(8) ChunkT;

    var encoder = Encoder.init(@TypeOf(value), &value);
    var list = std.ArrayList(ChunkPtrT).init(liu.Temp);

    while (true) {
        const chunk_ = try liu.Temp.alignedAlloc(ChunkT, 8, 1);
        const chunk = &chunk_[0];

        switch (encoder.encode(chunk)) {
            .done => |size| {
                return Encoded(chunk_size){ .chunks = list.items, .last = chunk[0..size] };
            },
            .not_done => {
                try list.append(chunk);
            },
        }
    }
}

const AssetError = error{
    NotAsset,
    VersionMismatch,
    InvalidData,
    TypeMismatch,
    OutOfBounds,
};

pub fn parse(comptime T: type, bytes: []align(8) const u8) !*const Spec.fromType(T).Type {
    if (bytes.len < @sizeOf(Header)) {
        return error.NotAsset;
    }

    // magic number
    if (!std.mem.eql(u8, bytes[0..4], "aliu")) {
        return error.NotAsset;
    }

    const version = @bitCast(u32, bytes[4..8].*);
    if (version > Version) {
        return error.VersionMismatch;
    }

    const data_begin = @bitCast(u32, bytes[8..12].*);
    if (data_begin > bytes.len) return error.OutOfBounds;
    if (data_begin % 8 != 0) return error.InvalidData;

    const spec_len = @bitCast(u32, bytes[12..16].*);
    const spec_end = 16 + spec_len;
    if (spec_end > data_begin) {
        return error.InvalidData;
    }

    const spec = Spec.fromType(T);
    const asset_spec = @ptrCast([]const Spec.Info, bytes[16..spec_end]);
    if (!std.mem.eql(Spec.Info, spec.Info, asset_spec)) {
        return error.TypeMismatch;
    }

    // TODO validation code

    return @ptrCast(*const spec.Type, bytes[data_begin..]);
}

test "Packed Asset: spec generation" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const TestE = extern struct {
        data: U32Slice(u8),
        field: u8,
    };

    const Test = struct {
        field: u8,
        data: []u8,
    };

    const spec = Spec.fromType(TestE);
    const spec2 = Spec.fromType(Test);

    try std.testing.expectEqualSlices(Spec.Info, spec.Info, spec2.Info);

    try std.testing.expectEqualSlices(Spec.Info, spec.Info, &.{
        .ustruct_open_4,
        .uslice_of_next,
        .pu8,
        .pu8,
        .ustruct_close,
    });
}

test "Packed Asset: spec encode/decode simple" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        field2: struct { asdf: u8, wasd: u8 },
        field: u64,
    };

    const spec = Spec.fromType(Test);

    // std.debug.print("specInfo: {any}\n", .{spec.Info});

    try std.testing.expectEqualSlices(Spec.Info, spec.Info, &.{
        .ustruct_open_8,
        .pu64,
        .ustruct_open_1,
        .pu8,
        .pu8,
        .ustruct_close,
        .ustruct_close,
    });

    const t: Test = .{ .field = 120303113, .field2 = .{ .asdf = 100, .wasd = 255 } };
    const encoded = try tempEncode(t, null);

    try std.testing.expect(encoded.chunks.len == 0);

    const value = try parse(Test, encoded.last);

    // std.debug.print("{any} {any}\n", .{ t, value.* });

    try std.testing.expectEqual(value.field, t.field);
    try std.testing.expectEqual(value.field2.asdf, t.field2.asdf);
    try std.testing.expectEqual(value.field2.wasd, t.field2.wasd);
}

test "Packed Asset: encode/decode extern" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const TestE = extern struct {
        data: u64,
        field: u8,
    };

    const Test = struct {
        field: u8,
        data: u64,
    };

    const spec = Spec.fromType(Test);

    try std.testing.expectEqualSlices(Spec.Info, spec.Info, &.{
        .ustruct_open_8,
        .pu64,
        .pu8,
        .ustruct_close,
    });

    const t: TestE = .{ .field = 123, .data = 12398145 };
    const encoded = try tempEncode(t, 24);

    try std.testing.expect(encoded.chunks.len == 1);

    const bytes = try encoded.copyContiguous(liu.Temp);

    const value = try parse(TestE, bytes);

    try std.testing.expectEqual(value.*, t);
}

test "Packed Asset: spec encode/decode multiple chunks" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        field0: u64 = 0,
        field1: u64 = 1,
        field2: u64 = 2,
        field3: u64 = 3,
        field4: u64 = 4,
        field5: u64 = 5,
        field6: u64 = 6,
        field7: u64 = 7,
        field8: u64 = 8,
        field9: u64 = 9,
        field10: u64 = 10,
        field11: u64 = 11,
        field12: u64 = 12,
        field13: u64 = 13,
        field14: u64 = 14,
        field15: u64 = 15,
        field16: u64 = 16,
        field17: u64 = 17,
        field18: u64 = 18,
        field19: u64 = 19,
        field20: u64 = 20,
        field21: u64 = 21,
        field22: u64 = 22,
        field23: u64 = 23,
        field24: u64 = 24,
        field25: u64 = 25,
        field26: u64 = 26,
        field27: u64 = 27,
        field28: u64 = 28,
        field29: u64 = 29,
        field30: u64 = 30,
        field31: u64 = 31,
        field32: u64 = 32,
        field33: u64 = 33,
        field34: u64 = 34,
        field35: u64 = 35,
        field36: u64 = 36,
        field37: u64 = 37,
        field38: u64 = 38,
        field39: u64 = 39,
        field40: u64 = 40,
        field41: u64 = 41,
        field42: u64 = 42,
        field43: u64 = 43,
        field44: u64 = 44,
        field45: u64 = 45,
        field46: u64 = 46,
        field47: u64 = 47,
        field48: u64 = 48,
        field49: u64 = 49,
    };

    const spec = Spec.fromType(Test);

    // std.debug.print("specInfo: {any}\n", .{spec.Info});

    try std.testing.expectEqual(spec.Info[0], .ustruct_open_8);
    try std.testing.expectEqual(spec.Info[spec.Info.len - 1], .ustruct_close);

    try std.testing.expectEqualSlices(Spec.Info, spec.Info[1..(spec.Info.len - 1)], &.{
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
        .pu64, .pu64, .pu64, .pu64, .pu64,
    });

    const t: Test = .{};
    const encoded = try tempEncode(t, 304);

    try std.testing.expect(encoded.chunks.len == 1);

    const bytes = try encoded.copyContiguous(liu.Temp);

    const value = try parse(Test, bytes);

    const values = @ptrCast(*const [50]u64, value);
    for (values) |v, i| {
        try std.testing.expectEqual(v, i);
    }
}
