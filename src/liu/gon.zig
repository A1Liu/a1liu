const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const SchemaParseError = std.fmt.ParseIntError || error{
    MissingField,
    ExpectedStruct,
    ExpectedPrimitive,
    ExpectedString,
    ExpectedArray,

    OnlyStringSlicesSupported,
};

pub const Value = union(enum) {
    map: Map,
    array: Array,
    value: []const u8,

    const Map = std.StringArrayHashMapUnmanaged(Self);
    const Array = std.ArrayListUnmanaged(Self);

    const Self = @This();

    pub fn init(val: anytype) error{OutOfMemory}!Self {
        const T = @TypeOf(val);

        if (T == Self) {
            return val;
        }

        switch (@typeInfo(T)) {
            .Struct => |info| {
                var map: Map = .{};
                try map.ensureTotalCapacity(liu.Temp, info.fields.len);

                inline for (info.fields) |field| {
                    const field_val = @field(val, field.name);

                    const field_gon = try Value.init(field_val);
                    map.putAssumeCapacity(field.name, field_gon);
                }

                return Self{ .map = map };
            },

            .Pointer => |info| {
                if (info.size != .Slice) @compileError("We only support strings ([]const u8)");
                if (info.child != u8) @compileError("We only support strings ([]const u8)");
                if (!info.is_const) @compileError("We only support strings ([]const u8)");

                return Self{ .value = val };
            },

            else => @compileError("unsupported type for GON"),
        }
    }

    pub fn expect(self: *const Self, comptime T: type) SchemaParseError!T {
        if (T == Self) {
            return self.*;
        }

        switch (@typeInfo(T)) {
            .Struct => |info| {
                if (self.* != .map) return error.ExpectedStruct;

                var t: T = undefined;
                const map = &self.map;

                inline for (info.fields) |field| {
                    const map_value = map.get(field.name);
                    const field_info = @typeInfo(field.field_type);
                    if (field_info == .Optional) {
                        if (map_value) |value| {
                            const field_type = field_info.Optional.child;
                            @field(t, field.name) = try value.expect(field_type);
                        } else {
                            @field(t, field.name) = null;
                        }
                    } else {
                        const value = map_value orelse return error.MissingField;

                        @field(t, field.name) = try value.expect(field.field_type);
                    }
                }

                return t;
            },

            .Pointer => |info| {
                if (info.size != .Slice) @compileError("We only support strings ([]const u8)");
                if (info.child != u8) @compileError("We only support strings ([]const u8)");
                if (!info.is_const) @compileError("We only support strings ([]const u8)");

                if (self.* != .value) return error.ExpectedString;

                return self.value;
            },

            else => @compileError("wtf"),
        }
    }

    pub fn write(self: *const Self, writer: anytype, is_root: bool) !void {
        const indent: u32 = if (is_root) 0 else 2;
        try self.writeRecursive(writer, indent, is_root);
    }

    fn writeRecursive(
        self: *const Self,
        writer: anytype,
        indent: u32,
        is_root: bool,
    ) @TypeOf(writer).Error!void {
        switch (self.*) {
            .map => |map| {
                if (!is_root) {
                    try writer.writeByte('{');
                    try writer.writeByte('\n');
                }

                var iter = map.iterator();

                while (iter.next()) |i| {
                    try writer.writeByteNTimes(' ', indent);
                    try std.fmt.format(writer, "{s} ", .{i.key_ptr.*});
                    try i.value_ptr.writeRecursive(writer, indent + 2, false);
                    try writer.writeByte('\n');
                }

                if (!is_root) {
                    try writer.writeByteNTimes(' ', indent - 2);
                    try writer.writeByte('}');
                }
            },
            .array => |array| {
                try writer.writeByte('[');
                try writer.writeByte('\n');

                for (array.items) |i| {
                    try writer.writeByteNTimes(' ', indent);
                    try i.writeRecursive(writer, indent + 2, false);
                    try writer.writeByte('\n');
                }

                try writer.writeByteNTimes(' ', indent - 2);
                try writer.writeByte(']');
            },
            .value => |value| {
                try std.fmt.format(writer, "{s}", .{value});
            },
        }
    }
};

pub const Token = union(enum) {
    string: []const u8,
    lbrace,
    rbrace,
    lbracket,
    rbracket,
};

fn tokenize(bytes: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(liu.Pages);
    errdefer tokens.deinit();

    var i: u32 = 0;
    var word_begin: ?u32 = null;

    while (i < bytes.len) : (i += 1) {
        const b = bytes[i];
        const tok_opt: ?Token = switch (b) {
            ' ', '\t', '\n' => null,

            '{' => .lbrace,
            '}' => .rbrace,
            '[' => .lbracket,
            ']' => .rbracket,

            else => {
                if (word_begin == null)
                    word_begin = i;
                continue;
            },
        };

        if (word_begin) |begin| {
            try tokens.append(.{ .string = bytes[begin..i] });
        }

        word_begin = null;
        if (tok_opt) |tok| {
            try tokens.append(tok);
        }
    }

    if (word_begin) |begin| {
        try tokens.append(.{ .string = bytes[begin..i] });
    }

    return tokens;
}

const ParseError = error{
    OutOfMemory,
    UnexpectedToken,
};

const Parser = struct {
    tokens: []const Token,
    index: u32 = 0,

    fn parseGonRecursive(self: *@This(), is_root: bool) ParseError!Value {
        const mark = liu.TempMark;
        errdefer liu.TempMark = mark;

        while (self.index < self.tokens.len) {
            if (self.tokens[self.index] == .lbracket) {
                self.index += 1;
                var values: std.ArrayListUnmanaged(Value) = .{};

                while (self.index < self.tokens.len) {
                    if (self.tokens[self.index] == .rbracket) {
                        self.index += 1;
                        break;
                    }

                    const value = try self.parseGonRecursive(false);
                    try values.append(liu.Temp, value);
                }

                return Value{ .array = values };
            }

            const parse_as_object = if (self.tokens[self.index] != .lbrace) is_root else object: {
                self.index += 1;
                break :object true;
            };

            if (parse_as_object) {
                var values: Value.Map = .{};

                while (self.index < self.tokens.len) {
                    const tok = self.tokens[self.index];
                    self.index += 1;

                    switch (tok) {
                        .string => |s| {
                            const value = try self.parseGonRecursive(false);
                            try values.put(liu.Temp, s, value);
                        },

                        .rbrace => break,

                        else => return error.UnexpectedToken,
                    }
                }

                return Value{ .map = values };
            }

            const tok = self.tokens[self.index];
            self.index += 1;

            switch (tok) {
                .string => |s| return Value{ .value = s },
                else => return error.UnexpectedToken,
            }
        }

        return Value{ .value = "" };
    }
};

pub fn parseGon(bytes: []const u8) ParseError!Value {
    const tokens = try tokenize(bytes);
    defer tokens.deinit();

    var parser = Parser{ .tokens = tokens.items };
    return parser.parseGonRecursive(true);
}

test "GON: parse" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const output = try parseGon("Hello { blarg werp }\nKerrz [ helo blarg\n ] merp farg");

    var writer_out = std.ArrayList(u8).init(liu.Pages);
    defer writer_out.deinit();

    try output.write(writer_out.writer(), true);

    const expected = "Hello {\n  blarg werp\n}\nKerrz [\n  helo\n  blarg\n]\nmerp farg\n";
    try std.testing.expectEqualSlices(u8, expected, writer_out.items);

    const parsed = try output.expect(struct {
        Hello: Value,
        Kerrz: Value,
        merp: []const u8,
        zarg: ?[]const u8,
    });

    try std.testing.expectEqualSlices(u8, "farg", parsed.merp);
    try std.testing.expect(parsed.zarg == null);
}

test "GON: serialize" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        merp: []const u8 = "hello",
        zarg: []const u8 = "world",
    };

    const a = Test{};

    const value = try Value.init(a);

    var writer_out = std.ArrayList(u8).init(liu.Pages);
    defer writer_out.deinit();

    try value.write(writer_out.writer(), true);

    const expected = "merp hello\nzarg world\n";
    try std.testing.expectEqualSlices(u8, expected, writer_out.items);
}

test "GON: tokenize" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const tokens = try tokenize("Hello { blarg werp } Mark\n");
    const expected = [_]Token{
        .{ .string = "Hello" },
        .lbrace,
        .{ .string = "blarg" },
        .{ .string = "werp" },
        .rbrace,
        .{ .string = "Mark" },
    };

    for (tokens.items) |t, i| {
        const s = switch (t) {
            .string => |s| s,
            else => {
                try std.testing.expectEqual(expected[i], t);
                continue;
            },
        };

        const e = switch (expected[i]) {
            .string => |e| e,
            else => return error.Failed,
        };

        try std.testing.expectEqualSlices(u8, e, s);
    }
}
