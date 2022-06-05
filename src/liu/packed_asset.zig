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
        field_offset: ?u32 = null, // ignored when it doesn't apply
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
                    if (info.signedness == .signed or info.bits != 8)
                        @compileError("only handles u8 right now");

                    return &.{EncodeInfo{ .type_info = .pu8 }};
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
                            const first_info = EncodeInfo{
                                .type_info = encode_info[0].type_info,
                                .field_offset = @offsetOf(B, field.name),
                            };
                            spec = spec ++ &[_]EncodeInfo{first_info} ++ encode_info[1..];
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

            for (info.fields) |field| {
                const FieldT = translateType(field.field_type);

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
    spec: []const Spec.EncodeInfo,
    file_offset: u32 = 0,

    object: [*]const u8,
    object_base: u32 = 0,

    const Result = union(enum) {
        done: u32,
        not_done: void,
    };

    fn init(comptime T: type, value: *const T) @This() {
        return .{
            .spec = Spec.fromType(T).EncodeInfo,
            .object = @ptrCast([*]const u8, value),
        };
    }

    fn encode(self: *@This(), chunk: []align(8) u8) Result {
        std.debug.assert(chunk.len % 8 == 0);
        std.debug.assert(chunk.len >= 512);

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

        for (self.spec) |s, i| {
            if (s.type_info == .ustruct_close) {
                continue;
            }

            const alignment = s.type_info.alignment();
            const aligned_cursor = @truncate(u32, std.mem.alignForward(cursor, alignment));

            // fill padding with zeroes
            std.mem.set(u8, chunk[cursor..aligned_cursor], 0);

            cursor = aligned_cursor;

            if (cursor == len) {
                self.spec = self.spec[i..];
                return .not_done;
            }

            // TODO encode lol
            const object_offset = s.field_offset orelse cursor - self.object_base;

            const field_mem = self.object + object_offset;
            if (s.type_info.pSize()) |size| {
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
            }

            _ = s;
        }

        return .{ .done = cursor };
    }
};

fn Encoded(comptime chunk_size: u32) type {
    return struct {
        chunks: []*align(8) [chunk_size]u8,
        last_size: u32,
    };
}

const DefaultChunkSize = 16 * 4096;
pub fn tempEncode(value: anytype, comptime chunk_size_: ?u32) !Encoded(chunk_size_ orelse DefaultChunkSize) {
    const chunk_size = chunk_size_ orelse DefaultChunkSize;
    if (comptime chunk_size % 8 != 0)
        @compileError("chunk size must be aligned to 8 bytes");
    if (comptime chunk_size < 512)
        @compileError("chunk size should be at least 512 bytes");

    const ChunkT = [chunk_size]u8;
    const ChunkPtrT = *align(8) ChunkT;

    var encoder = Encoder.init(@TypeOf(value), &value);
    var list = std.ArrayList(ChunkPtrT).init(liu.Temp);

    while (true) {
        const chunk_ = try liu.Temp.alignedAlloc(ChunkT, 8, 1);
        const chunk = &chunk_[0];

        try list.append(chunk);

        switch (encoder.encode(chunk)) {
            .done => |size| {
                return Encoded(chunk_size){ .chunks = list.items, .last_size = size };
            },
            .not_done => {},
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

pub fn parse(comptime T: type, bytes: []align(8) u8) !*Spec.fromType(T).Type {
    if (bytes.len < 16) {
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

    return @ptrCast(*spec.Type, bytes[data_begin..]);
}

test "Packed Asset: spec generation" {
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
    try std.testing.expect(std.mem.eql(Spec.Info, spec.Info, spec2.Info));

    try std.testing.expect(std.mem.eql(Spec.Info, spec.Info, &.{
        .ustruct_open_4,
        .uslice_of_next,
        .pu8,
        .pu8,
        .ustruct_close,
    }));
}

test "Packed Asset: spec encode/decode simple" {
    const Test = struct {
        field: u8,
        field2: u8,
    };

    const spec = Spec.fromType(Test);
    try std.testing.expect(std.mem.eql(Spec.Info, spec.Info, &.{
        .ustruct_open_1,
        .pu8,
        .pu8,
        .ustruct_close,
    }));

    const t: Test = .{ .field = 13, .field2 = 12 };
    const encoded = try tempEncode(t, null);

    std.debug.print("len={} size={}\n", .{ encoded.chunks.len, encoded.last_size });
    try std.testing.expect(encoded.chunks.len == 1);

    const bytes = encoded.chunks[0][0..encoded.last_size];
    const value = try parse(Test, bytes);

    std.debug.print("{any} {any}\n", .{ t, value.* });

    try std.testing.expect(value.field == t.field);
    try std.testing.expect(value.field2 == t.field2);

    std.debug.print("{}\n", .{std.fmt.fmtSliceHexLower(bytes)});

    _ = encoded;
}
