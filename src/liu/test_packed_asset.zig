const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const Spec = liu.packed_asset.Spec;
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

    try std.testing.expectEqualSlices(Spec.TypeInfo, spec.typeInfo(), spec2.typeInfo());

    try std.testing.expectEqualSlices(Spec.TypeInfo, spec.typeInfo(), &.{
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

    try std.testing.expectEqualSlices(Spec.TypeInfo, spec.typeInfo(), &.{
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

    try std.testing.expectEqualSlices(Spec.TypeInfo, spec.typeInfo(), &.{
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
    const type_info = spec.typeInfo();

    try std.testing.expectEqual(type_info[0], .ustruct_open_8);
    try std.testing.expectEqual(type_info[type_info.len - 1], .ustruct_close_8);

    try std.testing.expectEqualSlices(Spec.TypeInfo, type_info[1..(type_info.len - 1)], &.{
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

test "Packed Asset: spec encode/decode slices" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        field: u16,
        data: []const u8,
    };

    const spec = Spec.fromType(Test);
    const type_info = spec.typeInfo();

    try std.testing.expectEqualSlices(Spec.TypeInfo, type_info, &.{
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
