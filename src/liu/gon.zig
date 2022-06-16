const std = @import("std");
const builtin = @import("builtin");
const liu = @import("./lib.zig");

pub const Value = struct {};

pub const Token = union(enum) {
    string: []const u8,
    lbrace,
    rbrace,
    lbracket,
    rbracket,
};

fn tokenize(bytes: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(liu.Pages);

    var i: u32 = 0;
    var word_begin: ?u32 = null;

    while (i < bytes.len) : (i += 1) {
        const b = bytes[i];
        const tok_opt: ?Token = switch (b) {
            ' ', '\t', '\n' => null,

            'a'...'z', 'A'...'Z', '.', '_', '0'...'9' => {
                if (word_begin == null)
                    word_begin = i;
                continue;
            },

            '{' => .lbrace,
            '}' => .rbrace,
            '[' => .lbracket,
            ']' => .rbracket,

            else => null,
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

pub fn parseGon(bytes: []const u8) !Value {
    const tokens = try tokenize(bytes);
    _ = tokens;

    return .{};
}

test "GON: tokenize" {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const tokens = try tokenize("Hello { blarg werp }\n");
    const expected = [_]Token{
        .{ .string = "Hello" },
        .lbrace,
        .{ .string = "blarg" },
        .{ .string = "werp" },
        .rbrace,
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
