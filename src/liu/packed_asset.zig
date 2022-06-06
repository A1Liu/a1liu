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

const assert = std.debug.assert;

const SliceMarker: u8 = 0;
pub fn U32Slice(comptime T: type) type {
    return extern struct {
        word_offset: u32,
        len: u32,

        pub const SliceType = T;
        const LiuPackedAssetDummyField: *const u8 = &SliceMarker;

        pub fn slice(self: *const @This()) []const T {
            const address = @ptrToInt(self);

            var out: []T = &.{};
            out.ptr = @intToPtr([*]T, 4 * self.word_offset + address);
            out.len = self.len;

            return out;
        }
    };
}

const native_endian = builtin.target.cpu.arch.endian();

const Version: u32 = 0;
const Header = extern struct {
    magic: [4]u8 = "aliu"[0..4].*,
    version: u32 = Version,
    data_begin: u32,
    spec_len: u32,
};

pub const Spec = struct {
    Type: type,
    encoder_info: []const EncoderInfo,
    header: Header,

    comptime {
        if (native_endian != .Little)
            @compileError("target platform must be little endian");
    }

    pub const TypeInfo = enum(u8) {
        // zig fmt: off
        pu8, pu16, pu32, pu64,
        pi8, pi16, pi32, pi64,
        pf32, pf64,

        uslice_of_next, // align 4, size 8

        // alignment comes from trailing number
        ustruct_open_1, ustruct_open_2, ustruct_open_4, ustruct_open_8,
        ustruct_close_1, ustruct_close_2, ustruct_close_4, ustruct_close_8,
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

        const Desc = struct {
            alignment: u16,
            kind: union(enum) { struct_close, struct_open, slice_of_next, prim: u8 },
        };

        fn descriptor(self: @This()) Desc {
            return switch (self) {
                .pu8, .pi8 => .{ .alignment = 1, .kind = .{ .prim = 1 } },
                .pu16, .pi16 => .{ .alignment = 2, .kind = .{ .prim = 2 } },
                .pu32, .pi32, .pf32 => .{ .alignment = 4, .kind = .{ .prim = 4 } },
                .pu64, .pi64, .pf64 => .{ .alignment = 8, .kind = .{ .prim = 8 } },

                .uslice_of_next => .{ .alignment = 4, .kind = .slice_of_next },

                .ustruct_open_1 => .{ .alignment = 1, .kind = .struct_open },
                .ustruct_open_2 => .{ .alignment = 2, .kind = .struct_open },
                .ustruct_open_4 => .{ .alignment = 4, .kind = .struct_open },
                .ustruct_open_8 => .{ .alignment = 8, .kind = .struct_open },

                .ustruct_close_1 => .{ .alignment = 1, .kind = .struct_close },
                .ustruct_close_2 => .{ .alignment = 2, .kind = .struct_close },
                .ustruct_close_4 => .{ .alignment = 4, .kind = .struct_close },
                .ustruct_close_8 => .{ .alignment = 8, .kind = .struct_close },

                else => unreachable,
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

                .ustruct_close_1 => 1,
                .ustruct_close_2 => 2,
                .ustruct_close_4 => 4,
                .ustruct_close_8 => 8,

                else => 0,
            };
        }
    };

    pub const EncoderInfo = struct { type_info: TypeInfo, offset: u32 = 0 };

    pub fn typeInfo(comptime self: @This()) []const TypeInfo {
        comptime {
            var info: []const TypeInfo = &.{};
            for (self.encoder_info) |e| {
                info = info ++ &[_]TypeInfo{e.type_info};
            }

            return info;
        }
    }

    pub fn fromType(comptime T: type) @This() {
        comptime {
            const ExternType = translateType(T);

            const encode_info = makeInfo(ExternType, T);

            const spec_len = @truncate(u32, encode_info.len);
            const header = Header{
                .data_begin = @truncate(u32, std.mem.alignForward(16 + spec_len, 8)),
                .spec_len = spec_len,
            };

            return .{
                .Type = ExternType,
                .encoder_info = encode_info,
                .header = header,
            };
        }
    }

    fn isInternalSlice(comptime T: type) bool {
        comptime {
            return @typeInfo(T) == .Struct and @hasDecl(T, "LiuPackedAssetDummyField") and
                T.LiuPackedAssetDummyField == &SliceMarker;
        }
    }

    fn makeInfo(comptime Extern: type, comptime Base: type) []const EncoderInfo {
        // @compileLog(Extern, Base);

        comptime {
            const info = switch (@typeInfo(Extern)) {
                .Int => |info| {
                    const type_info: TypeInfo = switch (info.bits) {
                        8 => if (info.signedness == .signed) .pi8 else .pu8,
                        16 => if (info.signedness == .signed) .pi16 else .pu16,
                        32 => if (info.signedness == .signed) .pi32 else .pu32,
                        64 => if (info.signedness == .signed) .pi64 else .pu64,
                        else => @compileError("doesn't handle non-standard integer sizes"),
                    };

                    return &.{EncoderInfo{ .type_info = type_info }};
                },

                .Struct => |info| info,

                .Pointer => @compileError("Native pointers are unsupported. " ++
                    "If you're looking for slices, use the custom wrapper type instead"),

                else => @compileError("Unsupported type: " ++ @typeName(Extern)),
            };

            // There's an argument you could make that this should actually
            // accept only packed and not extern. Extern is easier to implement.
            //                      - Albert Liu, Jun 04, 2022 Sat 14:48 PDT
            if (info.layout != .Extern)
                @compileError("struct must be laid out using extern format");

            if (isInternalSlice(Extern)) {
                const ElemBase = if (isInternalSlice(Base))
                    Extern.SliceType
                else
                    std.meta.Child(Base);

                const elem_type = makeInfo(Extern.SliceType, ElemBase);
                const slice_info = Spec.EncoderInfo{
                    .type_info = .uslice_of_next,
                };

                return &[_]EncoderInfo{slice_info} ++ elem_type;
            }

            const spec_info: [2]TypeInfo = switch (@alignOf(Extern)) {
                1 => .{ .ustruct_open_1, .ustruct_close_1 },
                2 => .{ .ustruct_open_2, .ustruct_close_2 },
                4 => .{ .ustruct_open_4, .ustruct_close_4 },
                8 => .{ .ustruct_open_8, .ustruct_close_8 },
                else => unreachable,
            };

            const val = EncoderInfo{ .type_info = spec_info[0] };

            var spec: []const Spec.EncoderInfo = &[_]EncoderInfo{val};

            var b: Base = undefined;

            for (info.fields) |field| {
                const BField = @TypeOf(@field(b, field.name));
                const encode_info = makeInfo(field.field_type, BField);
                if (encode_info.len == 1) {
                    // This means its a primitive

                    const new_info = EncoderInfo{
                        .type_info = encode_info[0].type_info,
                        .offset = @offsetOf(Base, field.name),
                    };

                    spec = spec ++ &[_]EncoderInfo{new_info};
                    continue;
                }

                var iter = Encoder.EncoderInfoIter{ .info = encode_info };
                while (iter.peek()) |sa| : (iter.index = sa.next_index) {
                    const offset = sa.offset + @offsetOf(Base, field.name);
                    const new_info = EncoderInfo{
                        .type_info = sa.type_info,
                        .offset = offset,
                    };

                    spec = spec ++ &[_]EncoderInfo{new_info};
                    if (sa.slice_info) |slice_info|
                        spec = spec ++ slice_info.spec;
                }
            }

            return spec ++ &[_]Spec.EncoderInfo{.{ .type_info = spec_info[1] }};
        }
    }

    fn translateType(comptime T: type) type {
        if (@sizeOf(T) == 0)
            @compileError("type has size of 0, what would you even store in the asset file?");
        if (@alignOf(T) > 8)
            @compileError("maximum alignment for values is 8");
        if (@alignOf(T) == 0)
            @compileError("what does align=0 even mean");

        const Field = std.builtin.Type.StructField;

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

            if (isInternalSlice(T)) return T;

            var translated: []const Field = &.{};

            // NOTE: we use change_count instead of a boolean here, even though
            // the eventual data we need is just a boolean, because it allows
            // us to prevent a branch during comptime. Maybe this is necessary,
            // maybe its not, it's unclear. We're hovering right at that 1000
            // mark right now for one of the test cases.
            var change_count: usize = 0;
            for (info.fields) |field| {
                const FieldT = translateType(field.field_type);
                change_count += @boolToInt(FieldT != field.field_type);

                const to_add = Field{
                    .name = field.name,
                    .field_type = FieldT,
                    .default_value = null,
                    .is_comptime = false,
                    .alignment = @alignOf(FieldT),
                };

                translated = translated ++ &[_]Field{to_add};
            }

            if (info.layout == .Extern) {
                if (change_count == 0) return T;

                return @Type(.{ .Struct = .{
                    .layout = .Extern,
                    .decls = &.{},
                    .is_tuple = false,
                    .fields = translated,
                } });
            }

            var fields: []const Field = &.{};

            // This process is just for sorting fields by alignment,
            // it's not using sort because sorting Fields isn't really
            // allowed at compile-time.
            for (translated) |field| {
                if (field.alignment == 8) fields = fields ++ &[_]Field{field};
            }

            for (translated) |field| {
                if (field.alignment == 4) fields = fields ++ &[_]Field{field};
            }

            for (translated) |field| {
                if (field.alignment == 2) fields = fields ++ &[_]Field{field};
            }

            for (translated) |field| {
                if (field.alignment == 1) fields = fields ++ &[_]Field{field};
            }

            return @Type(.{ .Struct = .{
                .layout = .Extern,
                .decls = &.{},
                .is_tuple = false,
                .fields = fields,
            } });
        }
    }
};

const Encoder = struct {
    header: Header,

    file_offset: u32 = 0,
    slice_data: std.ArrayListUnmanaged(SliceInfo) = .{},
    next_slice_data: u32 = 0,
    next_slice_offset: u32,

    iter: EncoderInfoIter,
    object: [*]const u8,
    object_size: u32,
    obj_left: u32 = 1,

    const Self = @This();

    const SliceInfo = struct {
        spec: []const Spec.EncoderInfo,
        data: [*]const u8,
        obj_left: u32,
        obj_size: u32,
        offset: u32,
    };

    const Result = union(enum) {
        done: u32,
        not_done: void,
    };

    const ObjectDesc = struct {
        spec: []const Spec.EncoderInfo,
        size: u32,
        alignment: u16,
    };

    const EncoderInfoIter = struct {
        info: []const Spec.EncoderInfo,
        index: usize = 0,
        struct_count: u32 = 0,

        const SA = struct {
            next_index: usize = undefined,
            type_info: Spec.TypeInfo = undefined,
            size: u32,
            alignment: u16,
            offset: u32 = 0,
            slice_info: ?ObjectDesc = null,
        };

        const Desc = struct {
            alignment: u16,
            kind: union(enum) { struct_close, struct_open, slice_of_next, prim: u8 },
        };

        fn peek(self: *@This()) ?SA {
            if (self.index != 0 and self.struct_count == 0) return null;
            if (self.index >= self.info.len) return null;

            var sa = SA{ .size = 0, .alignment = 0 };
            var index: usize = self.index;

            const encoder_info = self.info[index];

            const desc: Desc = switch (encoder_info.type_info) {
                .pu8, .pi8 => .{ .alignment = 1, .kind = .{ .prim = 1 } },
                .pu16, .pi16 => .{ .alignment = 2, .kind = .{ .prim = 2 } },
                .pu32, .pi32, .pf32 => .{ .alignment = 4, .kind = .{ .prim = 4 } },
                .pu64, .pi64, .pf64 => .{ .alignment = 8, .kind = .{ .prim = 8 } },

                .uslice_of_next => .{ .alignment = 4, .kind = .slice_of_next },

                .ustruct_open_1 => .{ .alignment = 1, .kind = .struct_open },
                .ustruct_open_2 => .{ .alignment = 2, .kind = .struct_open },
                .ustruct_open_4 => .{ .alignment = 4, .kind = .struct_open },
                .ustruct_open_8 => .{ .alignment = 8, .kind = .struct_open },

                .ustruct_close_1 => .{ .alignment = 1, .kind = .struct_close },
                .ustruct_close_2 => .{ .alignment = 2, .kind = .struct_close },
                .ustruct_close_4 => .{ .alignment = 4, .kind = .struct_close },
                .ustruct_close_8 => .{ .alignment = 8, .kind = .struct_close },

                else => unreachable,
            };

            sa.type_info = encoder_info.type_info;
            sa.next_index = index + 1;
            sa.alignment = std.math.max(sa.alignment, desc.alignment);
            sa.offset = encoder_info.offset;

            switch (desc.kind) {
                .prim => |size| sa.size = size,
                .struct_open => self.struct_count += 1,

                .struct_close => {
                    self.struct_count -= 1;

                    sa.size = 0;
                },

                .slice_of_next => {
                    const remainder = self.info[(index + 1)..];
                    var info = objectInfo(remainder);
                    info.alignment = std.math.max(info.alignment, 4);

                    sa.next_index += info.spec.len;
                    sa.size = 8;
                    sa.slice_info = info;
                },
            }

            return sa;
        }
    };

    fn init(comptime T: type, value: *const T) Self {
        const spec = Spec.fromType(T);

        const obj_info = objectInfo(spec.encoder_info);

        return .{
            .header = spec.header,
            .iter = .{ .info = spec.encoder_info },
            .object = @ptrCast([*]const u8, value),
            .object_size = obj_info.size,
            .next_slice_offset = spec.header.data_begin + obj_info.size,
        };
    }

    fn alignUp(cursor: u32, alignment: u16) u32 {
        return @truncate(u32, std.mem.alignForward(cursor, alignment));
    }

    fn objectInfo(spec: []const Spec.EncoderInfo) ObjectDesc {
        var iter: EncoderInfoIter = .{ .info = spec };
        var alignment: u16 = 0;
        var total_size: u32 = 0;

        while (iter.peek()) |sa| {
            alignment = std.math.max(alignment, sa.alignment);
            total_size = alignUp(total_size, sa.alignment);
            total_size += sa.size;
            iter.index = sa.next_index;
        }

        return .{
            .spec = spec[0..iter.index],
            .size = total_size,
            .alignment = alignment,
        };
    }

    fn encodeObj(self: *Self, cursor_: u32, chunk: []align(8) u8) !?u32 {
        const len = @truncate(u32, chunk.len);
        var cursor = cursor_;

        while (self.iter.peek()) |sa| {
            const aligned = alignUp(cursor, sa.alignment);
            std.mem.set(u8, chunk[cursor..aligned], 0); // fill padding with zeroes
            cursor = aligned;

            const field_mem = self.object + sa.offset;

            // NOTE: We don't have to do partial writes of fields here,
            // because we maintain the invariants that chunks are aligned
            // to 8 bytes and all primitive data has a maximum alignment/size of 8.
            if (cursor + sa.size > len) return null;

            defer cursor += sa.size;
            self.iter.index = sa.next_index;

            if (sa.slice_info) |info| {
                const raw_slice = @bitCast([]const u8, field_mem[0..@sizeOf([]const u8)].*);

                const obj_left = @truncate(u32, raw_slice.len);
                const offset = if (obj_left == 0) 0 else offset: {
                    const offset = alignUp(self.next_slice_offset, info.alignment);
                    try self.slice_data.append(liu.Pages, SliceInfo{
                        .spec = info.spec,
                        .data = raw_slice.ptr,
                        .obj_size = info.size,
                        .obj_left = obj_left,
                        .offset = offset,
                    });

                    const current_offset = cursor + self.file_offset;
                    const relative_offset = offset - current_offset;
                    assert(relative_offset % 4 == 0);

                    self.next_slice_offset = offset + info.size * obj_left;

                    break :offset relative_offset;
                };

                chunk[cursor..][0..4].* = @bitCast([4]u8, offset / 4);
                chunk[cursor..][4..8].* = @bitCast([4]u8, obj_left);

                // TODO: slices

                // need to store the pre-calculated next offset,
                // then parse the spec and update the next_offset value
                // then add the slice information to the slice list for
                // further processing
                continue;
            }

            switch (sa.size) {
                0 => {},
                1 => chunk[cursor..][0..1].* = field_mem[0..1].*,
                2 => chunk[cursor..][0..2].* = field_mem[0..2].*,
                4 => chunk[cursor..][0..4].* = field_mem[0..4].*,
                8 => chunk[cursor..][0..8].* = field_mem[0..8].*,
                else => unreachable,
            }
        }

        return cursor;
    }

    fn encode(self: *Self, chunk: []align(8) u8) !Result {
        assert(chunk.len % 8 == 0);

        const len = @truncate(u32, chunk.len);

        var cursor: u32 = 0;
        defer self.file_offset += len;

        // We're in the first chunk, at offset 0. We can safely assume that we
        // have the spec of the root type in its spec field. At this point, we
        // need to output the header of the file.
        if (self.file_offset == 0) {
            const header = self.header;

            assert(self.next_slice_offset == header.data_begin + self.object_size);

            @ptrCast(*Header, chunk[0..16]).* = header;

            // spec array
            for (self.iter.info) |s, i| {
                chunk[i + 16] = @enumToInt(s.type_info);
            }

            // fill out padding between spec and data begin with zeros
            std.mem.set(u8, chunk[(16 + header.spec_len)..header.data_begin], 0);
            cursor = header.data_begin;
        }

        while (true) {
            while (self.obj_left > 0) {
                const new_cursor = try self.encodeObj(cursor, chunk);
                cursor = new_cursor orelse return Result.not_done;

                self.iter = .{ .info = self.iter.info };
                self.object += self.object_size;
                self.obj_left -= 1;
            }

            if (self.next_slice_data >= self.slice_data.items.len) break;

            const slice_data = self.slice_data.items[self.next_slice_data];
            self.next_slice_data += 1;

            if (self.next_slice_data >= self.slice_data.items.len) {
                self.next_slice_data = 0;
                self.slice_data.items.len = 0;
            }

            self.iter = .{ .info = slice_data.spec };
            self.object = slice_data.data;
            self.object_size = slice_data.obj_size;
            self.obj_left = slice_data.obj_left;

            const alignment = std.math.max(4, slice_data.spec[0].type_info.alignment());

            const aligned = alignUp(cursor, alignment);
            std.mem.set(u8, chunk[cursor..aligned], 0); // fill padding with zeroes
            cursor = aligned;
            assert(aligned + self.file_offset == slice_data.offset);
        }

        return Result{ .done = cursor };
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
    if (comptime chunk_size < spec.header.data_begin)
        @compileError("chunk size should be at least enough bytes to hold the header");

    const ChunkT = [chunk_size]u8;
    const ChunkPtrT = *align(8) ChunkT;

    var encoder = Encoder.init(@TypeOf(value), &value);
    var list = std.ArrayList(ChunkPtrT).init(liu.Temp);

    while (true) {
        const chunk_ = try liu.Temp.alignedAlloc(ChunkT, 8, 1);
        const chunk = &chunk_[0];

        switch (try encoder.encode(chunk)) {
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
    if (bytes.len < @sizeOf(Header)) return error.NotAsset;

    const header = @ptrCast(*const Header, bytes[0..16]);

    if (!std.mem.eql(u8, &header.magic, "aliu")) return error.NotAsset;
    if (header.version > Version) return error.VersionMismatch;

    if (header.data_begin > bytes.len) return error.OutOfBounds;
    if (header.data_begin % 8 != 0) return error.InvalidData;

    const spec_end = 16 + header.spec_len;
    if (spec_end > header.data_begin) return error.InvalidData;

    const spec = comptime Spec.fromType(T);
    const type_info = comptime spec.typeInfo();

    const asset_spec = @ptrCast([]const Spec.TypeInfo, bytes[16..spec_end]);
    if (!std.mem.eql(Spec.TypeInfo, type_info, asset_spec)) return error.TypeMismatch;

    // TODO validation code

    return @ptrCast(*const spec.Type, bytes[header.data_begin..]);
}

test {
    _ = @import("./packed_asset_test.zig");
}
