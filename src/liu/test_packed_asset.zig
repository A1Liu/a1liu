const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const Spec = liu.packed_asset.Spec;
const TypeInfo = liu.packed_asset.TypeInfo;
const tempEncode = liu.packed_asset.tempEncode;
const parse = liu.packed_asset.parse;
const U32Slice = liu.packed_asset.U32Slice;

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

    try std.testing.expectEqualSlices(TypeInfo, spec.typeInfo(), spec2.typeInfo());

    try std.testing.expectEqualSlices(TypeInfo, spec.typeInfo(), &.{
        .ustruct_open_4,
        .uslice_of_next,
        .pu8,
        .pu8,
        .ustruct_close_4,
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

    try std.testing.expectEqualSlices(TypeInfo, spec.typeInfo(), &.{
        .ustruct_open_8,
        .pu64,
        .ustruct_open_1,
        .pu8,
        .pu8,
        .ustruct_close_1,
        .ustruct_close_8,
    });

    const t: Test = .{ .field = 120303113, .field2 = .{ .asdf = 100, .wasd = 255 } };
    const encoded = try tempEncode(t, null);

    try std.testing.expect(encoded.chunks.len == 0);

    const value = try parse(Test, encoded.last);

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

    try std.testing.expectEqualSlices(TypeInfo, spec.typeInfo(), &.{
        .ustruct_open_8,
        .pu64,
        .pu8,
        .ustruct_close_8,
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
        field: u16,
        data: []const u64,
    };

    const spec = Spec.fromType(Test);
    const type_info = spec.typeInfo();

    try std.testing.expectEqualSlices(TypeInfo, type_info, &.{
        .ustruct_open_4,
        .uslice_of_next,
        .pu64,
        .pu16,
        .ustruct_close_4,
    });

    const t: Test = .{
        .field = 16,
        .data = &.{
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
        },
    };
    const encoded = try tempEncode(t, 32);

    try std.testing.expectEqual(encoded.chunks.len, 41);

    const bytes = try encoded.copyContiguous(liu.Temp);

    const value = try parse(Test, bytes);

    try std.testing.expectEqual(t.field, value.field);

    const slice = value.data.slice();

    const begin = @ptrToInt(slice.ptr);
    const end = @ptrToInt(slice.ptr + slice.len);

    try std.testing.expect(begin > @ptrToInt(bytes.ptr));
    try std.testing.expect(end <= @ptrToInt(bytes.ptr + bytes.len));

    try std.testing.expectEqualSlices(u64, t.data, slice);
}

test "Packed Asset: alignment" {
    const aligned_1: []const TypeInfo = &.{
        .pu8,
        .pi8,
        .ustruct_open_1, // struct alignment comes from trailing number
        .ustruct_close_1,
    };

    for (aligned_1) |t| {
        try std.testing.expectEqual(t.alignment(), 1);
    }

    const aligned_2: []const TypeInfo = &.{
        .pu16,
        .pi16,
        .ustruct_open_2,
        .ustruct_close_2,
    };

    for (aligned_2) |t| {
        try std.testing.expectEqual(t.alignment(), 2);
    }

    const aligned_4: []const TypeInfo = &.{
        .pu32,
        .pi32,
        .pf32,
        .uslice_of_next, // align 4, size 8
        .ustruct_open_4,
        .ustruct_close_4,
    };

    for (aligned_4) |t| {
        try std.testing.expectEqual(t.alignment(), 4);
    }

    const aligned_8: []const TypeInfo = &.{
        .pu64,
        .pi64,
        .pf64,
        .ustruct_open_8,
        .ustruct_close_8,
    };

    for (aligned_8) |t| {
        try std.testing.expectEqual(t.alignment(), 8);
    }
}

test "Packed Asset: spec encode/decode slices" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        field: u16,
        data: []const u8,
    };

    const spec = Spec.fromType(Test);
    const type_info = spec.typeInfo();

    try std.testing.expectEqualSlices(TypeInfo, type_info, &.{
        .ustruct_open_4,
        .uslice_of_next,
        .pu8,
        .pu16,
        .ustruct_close_4,
    });

    const t: Test = .{
        .field = 16,
        .data = &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    };
    const encoded = try tempEncode(t, 1024);

    try std.testing.expect(encoded.chunks.len == 0);

    const bytes = try encoded.copyContiguous(liu.Temp);

    const value = try parse(Test, bytes);

    try std.testing.expectEqual(t.field, value.field);

    const slice = value.data.slice();

    const begin = @ptrToInt(slice.ptr);
    const end = @ptrToInt(slice.ptr + slice.len);

    try std.testing.expect(begin > @ptrToInt(bytes.ptr));
    try std.testing.expect(end <= @ptrToInt(bytes.ptr + bytes.len));

    try std.testing.expectEqualSlices(u8, t.data, slice);
}

test "Packed Asset: spec branch quota" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        field1: u64,
        field2: u64,
        field3: u64,
        field4: u64,
        field5: u64,
        field6: u64,
        field7: u64,
        field8: u64,
        field9: u64,
        field10: u64,
        field11: u64,
        field12: u64,
        field13: u64,
        field14: u64,
        field15: u64,
        field16: u64,
        field17: u64,
        field18: u64,
        field19: u64,
        field20: u64,
        field21: u64,
        field22: u64,
        field23: u64,
        field24: u64,
        field25: u64,
        field26: u64,
        field27: u64,
        field28: u64,
        field29: u64,
        field30: u64,
        field31: u64,
        field32: u64,
        field33: u64,
        field34: u64,
        field35: u64,
        field36: u64,
        field37: u64,
        field38: u64,
        field39: u64,
        field40: u64,
        field41: u64,
        field42: u64,
        field43: u64,
        field44: u64,
        field45: u64,
        field46: u64,
        field47: u64,
        field48: u64,
        field49: u64,
        field50: u64,
        field51: u64,
        field52: u64,
        field53: u64,
        field54: u64,
        field55: u64,
        field56: u64,

        // Boundary
        // field57: u64,
        // field58: u64,
        // field59: u64,
        // field60: u64,
        // field61: u64,
        // field62: u64,
        // field63: u64,
        // field64: u64,
        // field65: u64,
        // field66: u64,
        // field67: u64,
        // field68: u64,
        // field69: u64,
        // field70: u64,
        // field71: u64,
        // field72: u64,
        // field73: u64,
        // field74: u64,
        // field75: u64,
        // field76: u64,
        // field77: u64,
        // field78: u64,
        // field79: u64,
        // field80: u64,
        // field81: u64,
        // field82: u64,
        // field83: u64,
        // field84: u64,
        // field85: u64,
        // field86: u64,
        // field87: u64,
        // field88: u64,
        // field89: u64,
        // field90: u64,
        // field91: u64,
        // field92: u64,
        // field93: u64,
        // field94: u64,
        // field95: u64,
        // field96: u64,
        // field97: u64,
        // field98: u64,
        // field99: u64,
        // field100: u64,
    };

    const Wrap = struct {
        field: Test,
    };

    const spec = Spec.fromType(Wrap);
    _ = spec;
}
