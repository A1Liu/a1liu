const std = @import("std");
const root = @import("root");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

const SchemaParseError =
    std.fmt.ParseIntError ||
    std.fmt.ParseFloatError ||
    std.mem.Allocator.Error ||
    error{
    MissingField,
    ExpectedStruct,
    ExpectedPrimitive,
    ExpectedString,
    ExpectedArray,

    InvalidBoolValue,
    InvalidArrayLength,
};

const SchemaSerializeError = error{
    OutOfMemory,
};

const formatFloatValue = if (@hasDecl(root, "gon_formatFloatValue")) root.gon_formatFloatValue else struct {
    fn formatFloatValue(value: f64, writer: anytype) !void {
        return std.fmt.format(writer, "{e}", .{value});
    }
}.formatFloatValue;

const parseFloat = if (@hasDecl(root, "gon_parseFloat")) root.gon_parseFloat else struct {
    fn parseFloat(bytes: []const u8) !f64 {
        return std.fmt.parseFloat(f64, bytes);
    }
}.parseFloat;

pub const Value = union(enum) {
    map: Map,
    array: Array,
    value: []const u8,

    const Array = std.ArrayListUnmanaged(Self);
    const Map = std.ArrayListUnmanaged(struct {
        key: []const u8,
        value: Value,
    });

    const Self = @This();

    pub fn init(val: anytype) SchemaSerializeError!Self {
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

                    if (@typeInfo(@TypeOf(field_val)) != .Optional) {
                        const field_gon = try Value.init(field_val);
                        map.appendAssumeCapacity(.{
                            .key = field.name,
                            .value = field_gon,
                        });
                    } else {
                        if (field_val) |f| {
                            const field_gon = try Value.init(f);
                            map.appendAssumeCapacity(.{
                                .key = field.name,
                                .value = field_gon,
                            });
                        }
                    }
                }

                return Self{ .map = map };
            },

            .Int => |_| {
                var bytes = std.ArrayList(u8).init(liu.Temp);
                try std.fmt.format(bytes.writer(), "{}", .{val});
                return Self{ .value = bytes.items };
            },

            .Float => |info| {
                if (info.bits > 64) @compileError("Only support floats up to f64");

                var bytes = std.ArrayList(u8).init(liu.Temp);

                try formatFloatValue(val, bytes.writer());

                return Self{ .value = bytes.items };
            },

            .Bool => {
                return if (val)
                    Self{ .value = "true" }
                else
                    Self{ .value = "false" };
            },

            .Pointer => |info| {
                if (info.size != .Slice) @compileError("We only support slices right now");

                if (info.child == u8) {
                    return Self{ .value = val };
                }

                var array = Array{};
                try array.ensureTotalCapacity(liu.Temp, val.len);

                for (val) |v| {
                    array.appendAssumeCapacity(try Value.init(v));
                }

                return Self{ .array = array };
            },

            .Array => |info| {
                var array = Array{};
                try array.ensureTotalCapacity(liu.Temp, info.len);

                for (val) |v| {
                    array.appendAssumeCapacity(try Value.init(v));
                }

                return Self{ .array = array };
            },

            .Vector => |info| {
                var array = Array{};
                try array.ensureTotalCapacity(liu.Temp, info.len);

                const elements: [info.len]info.child = val;
                for (elements) |v| {
                    array.appendAssumeCapacity(try Value.init(v));
                }

                return Self{ .array = array };
            },

            else => @compileError("unsupported type '" ++ @typeName(T) ++ "' for GON"),
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
                    var map_value: ?Value = null;

                    found: for (map.items) |kv| {
                        if (std.mem.eql(u8, kv.key, field.name)) {
                            map_value = kv.value;
                            break :found;
                        }
                    }

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

            .Bool => {
                if (self.* != .value) return error.ExpectedString;

                const value = self.value;

                if (std.mem.eql(u8, value, "true")) return true;
                if (std.mem.eql(u8, value, "false")) return false;

                return error.InvalidBoolValue;
            },

            .Int => |_| {
                if (self.* != .value) return error.ExpectedString;

                const out = try std.fmt.parseInt(T, self.value, 10);
                return out;
            },

            .Float => |info| {
                if (info.bits > 64)
                    @compileError("Only support floats up to f64");

                if (self.* != .value) return error.ExpectedString;

                const out = try parseFloat(self.value);
                return @floatCast(T, out);
            },

            .Vector => |info| {
                if (self.* != .array) return error.ExpectedArray;

                const values = self.array;
                if (values.items.len != info.len)
                    return error.InvalidArrayLength;

                var out: [info.len]info.child = undefined;

                for (values.items) |v, i| {
                    out[i] = try v.expect(info.child);
                }

                return out;
            },

            .Pointer => |info| {
                if (info.size != .Slice) @compileError("We only support strings ([]const u8)");

                if (info.child == u8) {
                    if (self.* != .value) return error.ExpectedString;

                    return self.value;
                }

                if (self.* != .array) return error.ExpectedArray;

                const vals = self.array;
                const out = try liu.Temp.alloc(info.child, vals.items.len);

                for (vals.items) |v, i| {
                    out[i] = try v.expect(info.child);
                }

                return out;
            },

            else => @compileError("unsupported type '" ++ @typeName(T) ++ "' for GON"),
        }
    }

    pub fn write(self: *const Self, writer: anytype, is_root: bool) @TypeOf(writer).Error!void {
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

                for (map.items) |kv| {
                    try writer.writeByteNTimes(' ', indent);
                    try writer.writeAll(kv.key);
                    try writer.writeByte(' ');
                    try kv.value.writeRecursive(writer, indent + 2, false);
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
                try writer.writeAll(value);
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
                            try values.append(liu.Temp, .{
                                .key = s,
                                .value = value,
                            });
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

    const output = try parseGon("Hello { blarg werp }\nKerrz [ helo blarg\n ]fasd 13\n merp farg\nwatta 1.0");

    var writer_out = std.ArrayList(u8).init(liu.Pages);
    defer writer_out.deinit();

    try output.write(writer_out.writer(), true);

    const expected = "Hello {\n  blarg werp\n}\nKerrz [\n  helo\n  blarg\n]\nfasd 13\nmerp farg\nwatta 1.0\n";
    try std.testing.expectEqualSlices(u8, expected, writer_out.items);

    const parsed = try output.expect(struct {
        Hello: Value,
        Kerrz: Value,
        fasd: u32,
        merp: []const u8,
        zarg: ?[]const u8,
        watta: f32,
    });

    try std.testing.expectEqualSlices(u8, "farg", parsed.merp);
    try std.testing.expect(parsed.zarg == null);
    try std.testing.expect(parsed.watta == 1.0);
}

test "GON: serialize" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const Test = struct {
        merp: []const u8 = "hello",
        zarg: []const u8 = "world",
        forts: u64 = 1231243,
        lerk: f64 = 13.0,
    };

    const a = Test{};

    const value = try Value.init(a);

    var writer_out = std.ArrayList(u8).init(liu.Pages);
    defer writer_out.deinit();

    try value.write(writer_out.writer(), true);

    const expected = "merp hello\nzarg world\nforts 1231243\nlerk 1.3e+01\n";
    // std.debug.print("{s}\n{s}\n", .{ expected, writer_out.items });
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
