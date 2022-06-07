const std = @import("std");
const liu = @import("./liu/lib.zig");

// This file stores the specifications of created assets and the code to
// re-generate them from valid data, where the valid data is easier to reason
// about than the produced asset files. Ideally the valid data is human-readable.

const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub const kilordle = struct {
    pub const Spec = struct {
        words: [5][]const u8,
        wordles: [5][]const u8,
    };

    fn soa_translation(alloc: Allocator, data: []const u8) ![5][]const u8 {
        const count = data.len / 6;

        const out: [5][]u8 = .{
            try alloc.alloc(u8, count),
            try alloc.alloc(u8, count),
            try alloc.alloc(u8, count),
            try alloc.alloc(u8, count),
            try alloc.alloc(u8, count),
        };

        var index: u32 = 0;
        while (index < count) : (index += 1) {
            const wordle_data = data[(index * 6)..][0..5];

            out[0][index] = wordle_data[0];
            out[1][index] = wordle_data[1];
            out[2][index] = wordle_data[2];
            out[3][index] = wordle_data[3];
            out[4][index] = wordle_data[4];
        }

        return out;
    }

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

        {
            var wordle_array_data = @ptrCast([][6]u8, wordles);
            wordle_array_data.len /= 6;

            std.sort.sort([6]u8, wordle_array_data, {}, struct {
                fn cmp(_: void, lhs: [6]u8, rhs: [6]u8) bool {
                    return std.mem.lessThan(u8, &lhs, &rhs);
                }
            }.cmp);
        }

        const words_out = try soa_translation(liu.Temp, words);
        const wordles_out = try soa_translation(liu.Temp, wordles);

        const out_data = Spec{
            .words = words_out,
            .wordles = wordles_out,
        };

        const encoded = try liu.packed_asset.tempEncode(out_data, null);

        const out_bytes = try encoded.copyContiguous(liu.Temp);

        try cwd.writeFile("static/kilordle/data.rtf", out_bytes);
    }
};
