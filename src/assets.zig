const std = @import("std");
const liu = @import("./liu/lib.zig");

pub const kilordle = struct {
    pub const Spec = struct {
        word0: []const u8,
        word1: []const u8,
        word2: []const u8,
        word3: []const u8,
        word4: []const u8,

        wordle0: []const u8,
        wordle1: []const u8,
        wordle2: []const u8,
        wordle3: []const u8,
        wordle4: []const u8,
    };

    pub fn generate() !void {
        const cwd = std.fs.cwd();
        const words = try cwd.readFileAllocOptions(
            liu.Temp,
            "src/routes/kilordle/wordle-words.txt",
            4096 * 4096,
            null,
            8,
            null,
        );

        const wordles = try cwd.readFileAllocOptions(
            liu.Temp,
            "src/routes/kilordle/wordles.txt",
            4096 * 4096,
            null,
            8,
            null,
        );

        _ = wordles;

        try cwd.writeFile("hello.txt", words);
    }
};
