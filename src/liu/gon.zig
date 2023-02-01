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
    InvalidEnumVariant,
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
    map: []const KV,
    array: []const Self,
    value: []const u8,

    const Self = @This();

    const KV = struct {
        key: []const u8,
        value: Value,
    };

    pub fn init(bump: *liu.Bump, val: anytype) SchemaSerializeError!Self {
        const T = @TypeOf(val);
        const alloc = bump.allocator();

        if (T == Self) {
            return val;
        }

        switch (@typeInfo(T)) {
            .Struct => |info| {
                var map = std.ArrayList(KV).init(alloc);

                try map.ensureTotalCapacity(info.fields.len);

                inline for (info.fields) |field| {
                    const field_val = @field(val, field.name);

                    if (@typeInfo(@TypeOf(field_val)) != .Optional) {
                        const field_gon = try Value.init(bump, field_val);
                        map.appendAssumeCapacity(.{
                            .key = field.name,
                            .value = field_gon,
                        });
                    } else if (field_val) |f| {
                        const field_gon = try Value.init(bump, f);
                        map.appendAssumeCapacity(.{
                            .key = field.name,
                            .value = field_gon,
                        });
                    }
                }

                return Self{ .map = map.items };
            },

            .Int => |_| {
                var bytes = std.ArrayList(u8).init(alloc);
                try std.fmt.format(bytes.writer(), "{}", .{val});
                return Self{ .value = bytes.items };
            },

            .Float => |info| {
                if (info.bits > 64) @compileError("Only support floats up to f64");

                var bytes = std.ArrayList(u8).init(alloc);

                try formatFloatValue(val, bytes.writer());

                return Self{ .value = bytes.items };
            },

            .Bool => {
                return if (val)
                    Self{ .value = "true" }
                else
                    Self{ .value = "false" };
            },

            .Enum => {
                return Self{ .value = @tagName(val) };
            },

            .Pointer => |info| {
                if (info.size != .Slice) @compileError("We only support slices right now");

                if (info.child == u8) {
                    return Self{ .value = val };
                }

                var array = std.ArrayList(Self).init(alloc);

                try array.ensureTotalCapacity(val.len);

                for (val) |v| {
                    array.appendAssumeCapacity(try Value.init(bump, v));
                }

                return Self{ .array = array.items };
            },

            .Array => |info| {
                var array = std.ArrayList(Self).init(alloc);

                try array.ensureTotalCapacity(info.len);

                for (val) |v| {
                    array.appendAssumeCapacity(try Value.init(bump, v));
                }

                return Self{ .array = array.items };
            },

            .Vector => |info| {
                var array = std.ArrayList(Self).init(alloc);

                try array.ensureTotalCapacity(info.len);

                const elements: [info.len]info.child = val;
                for (elements) |v| {
                    array.appendAssumeCapacity(try Value.init(bump, v));
                }

                return Self{ .array = array.items };
            },

            else => @compileError("unsupported type '" ++ @typeName(T) ++ "' for GON"),
        }
    }

    pub fn expect(self: *const Self, bump: *liu.Bump, comptime T: type) SchemaParseError!T {
        if (T == Self) {
            return self.*;
        }

        const alloc = bump.allocator();

        switch (@typeInfo(T)) {
            .Struct => |info| {
                if (self.* != .map) return error.ExpectedStruct;

                var t: T = undefined;

                inline for (info.fields) |field| {
                    var map_value: ?Value = null;

                    for (self.map) |kv| {
                        if (std.mem.eql(u8, kv.key, field.name)) {
                            map_value = kv.value;
                            break;
                        }
                    }

                    const field_info = @typeInfo(field.type);
                    if (field_info == .Optional) {
                        if (map_value) |value| {
                            const field_type = field_info.Optional.child;
                            @field(t, field.name) = try value.expect(bump, field_type);
                        } else {
                            @field(t, field.name) = null;
                        }
                    } else if (field.default_value) |default| {
                        if (map_value) |value| {
                            @field(t, field.name) = try value.expect(bump, field.type);
                        } else {
                            @field(t, field.name) = @ptrCast(*const field.type, default).*;
                        }
                    } else {
                        const value = map_value orelse return error.MissingField;

                        @field(t, field.name) = try value.expect(bump, field.type);
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

            .Enum => |_| {
                if (self.* != .value) return error.ExpectedString;

                return std.meta.stringToEnum(T, self.value) orelse error.InvalidEnumVariant;
            },

            .Vector => |info| {
                if (self.* != .array) return error.ExpectedArray;

                const values = self.array;
                if (values.len != info.len)
                    return error.InvalidArrayLength;

                var out: [info.len]info.child = undefined;

                for (values) |v, i| {
                    out[i] = try v.expect(bump, info.child);
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
                const out = try alloc.alloc(info.child, vals.len);

                for (vals) |v, i| {
                    out[i] = try v.expect(bump, info.child);
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

                for (map) |kv| {
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

                for (array) |i| {
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

fn tokenize(alloc: std.mem.Allocator, bytes: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(alloc);
    errdefer tokens.deinit();

    var i: u32 = 0;
    var prev_separator: ?u8 = null;
    var word_begin: ?u32 = null;

    while (i < bytes.len) : (i += 1) {
        var b = bytes[i];
        if (b == '\t') {
            b = ' ';
        }

        const tok_opt: ?Token = switch (b) {
            ' ' => null,
            '\n' => null,

            '{' => .lbrace,
            '}' => .rbrace,
            '[' => .lbracket,
            ']' => .rbracket,

            else => {
                prev_separator = null;
                if (word_begin == null)
                    word_begin = i;

                continue;
            },
        };

        if (word_begin) |begin| {
            try tokens.append(.{ .string = bytes[begin..i] });
        } else if (prev_separator) |sep| {
            if (b == '\n' and sep == ' ') {
                try tokens.append(.{ .string = "" });
            }
        }

        prev_separator = b;

        word_begin = null;
        if (tok_opt) |tok| {
            try tokens.append(tok);
        }
    }

    if (word_begin) |begin| {
        try tokens.append(.{ .string = bytes[begin..i] });
    } else if (prev_separator) |sep| {
        if (sep == ' ') {
            try tokens.append(.{ .string = "" });
        }
    }

    return tokens;
}

const ParseError = error{
    OutOfMemory,
    UnexpectedToken,
};

const Parser = struct {
    tokens: []const Token,
    arena: *liu.Bump,
    index: u32 = 0,

    fn parseGonRecursive(self: *@This(), is_root: bool) ParseError!Value {
        const alloc = self.arena.allocator();

        while (self.index < self.tokens.len) {
            if (self.tokens[self.index] == .lbracket) {
                self.index += 1;
                var values = std.ArrayList(Value).init(alloc);

                while (self.index < self.tokens.len) {
                    if (self.tokens[self.index] == .rbracket) {
                        self.index += 1;
                        break;
                    }

                    const value = try self.parseGonRecursive(false);
                    try values.append(value);
                }

                return Value{ .array = values.items };
            }

            const parse_as_object = if (self.tokens[self.index] != .lbrace) is_root else object: {
                self.index += 1;
                break :object true;
            };

            if (parse_as_object) {
                var values = std.ArrayList(Value.KV).init(alloc);

                while (self.index < self.tokens.len) {
                    const tok = self.tokens[self.index];
                    self.index += 1;

                    switch (tok) {
                        .string => |s| {
                            const value = try self.parseGonRecursive(false);
                            try values.append(.{
                                .key = s,
                                .value = value,
                            });
                        },

                        .rbrace => break,

                        else => return error.UnexpectedToken,
                    }
                }

                return Value{ .map = values.items };
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

// TODO Made a mistake with Temp allocator... rip

pub fn parseGon(bump: *liu.Bump, bytes: []const u8) ParseError!Value {
    const tokens = try tokenize(bump.allocator(), bytes);
    defer tokens.deinit();

    var parser = Parser{ .tokens = tokens.items, .arena = bump };
    return parser.parseGonRecursive(true);
}

test "GON: parse" {
    const temp = liu.Temp();
    defer temp.deinit();

    const output = try parseGon(temp.bump, "Hello { blarg werp }\nKerrz [ helo blarg\n ]fasd 13\n merp farg\nwatta 1.0");

    var writer_out = std.ArrayList(u8).init(temp.alloc);
    defer writer_out.deinit();

    try output.write(writer_out.writer(), true);

    const expected = "Hello {\n  blarg werp\n}\nKerrz [\n  helo\n  blarg\n]\nfasd 13\nmerp farg\nwatta 1.0\n";
    try std.testing.expectEqualSlices(u8, expected, writer_out.items);

    const parsed = try output.expect(temp.bump, struct {
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
    const temp = liu.Temp();
    defer temp.deinit();

    const Test = struct {
        merp: []const u8 = "hello",
        zarg: []const u8 = "world",
        forts: u64 = 1231243,
        lerk: f64 = 13.0,
    };

    const a = Test{};

    const value = try Value.init(temp.bump, a);

    var writer_out = std.ArrayList(u8).init(temp.alloc);
    defer writer_out.deinit();

    try value.write(writer_out.writer(), true);

    const expected = "merp hello\nzarg world\nforts 1231243\nlerk 1.3e+01\n";
    // std.debug.print("{s}\n{s}\n", .{ expected, writer_out.items });
    try std.testing.expectEqualSlices(u8, expected, writer_out.items);
}

test "GON: tokenize" {
    const temp = liu.Temp();
    defer temp.deinit();

    const tokens = try tokenize(temp.alloc, "Hello { blarg werp } Mark\n");
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
