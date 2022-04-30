const std = @import("std");
const assets = @import("assets");
const liu = @import("liu");

const wasm = liu.wasm;
usingnamespace wasm;

const WordSubmission = struct {
    word: [5]u8,
};

pub const WasmCommand = WordSubmission;

const Letters = std.bit_set.IntegerBitSet(26);
var found_letters: [5]Letters = [_]Letters{Letters.initEmpty()} ** 5;

fn searchList(word: []const u8, dict: []const u8) bool {
    var word_index: u32 = 0;
    while (word_index < dict.len) : (word_index += 6) {
        const dict_slice = dict[word_index..(word_index + 5)];

        if (std.mem.eql(u8, word, dict_slice)) {
            return true;
        }
    }

    return false;
}

export fn submitWord(l0: u8, l1: u8, l2: u8, l3: u8, l4: u8) void {
    const word = [_]u8{ l0, l1, l2, l3, l4 };
    var lowercased: [5]u8 = undefined;

    // lowercase
    for (word) |letter, idx| {
        if (letter < 'A' or letter > 'Z') {
            wasm.postFmt(.err, "invalid string {s}", .{word});
            return;
        }

        lowercased[idx] = letter - 'A' + 'a';
    }

    const is_wordle = searchList(&lowercased, assets.wordles);
    const is_extra = searchList(&lowercased, assets.wordle_words);
    if (!is_wordle and !is_extra) {
        wasm.postFmt(.err, "{s} doesn't exist", .{word});
        return;
    }

    // wasm.postFmt(.info, "{s} was found!", .{word});

    for (word) |letter, idx| {
        found_letters[idx].set(letter - 'A');
    }

    if (std.mem.eql(u8, &word, "BLUEY")) {
        wasm.postFmt(.info, "Blue!", .{});
    } else if (std.mem.eql(u8, &word, "AZURE")) {
        wasm.postFmt(.info, "Blue!", .{});
    } else if (std.mem.eql(u8, &word, "REDDY")) {
        wasm.postFmt(.err, "Red!", .{});
    } else if (std.mem.eql(u8, &word, "READY")) {
        wasm.postFmt(.err, "Red!", .{});
    } else if (std.mem.eql(u8, &word, "TANGY")) {
        wasm.postFmt(.warn, "Orange!", .{});
    } else if (std.mem.eql(u8, &word, "GREEN")) {
        wasm.postFmt(.success, "Green!", .{});
    } else {
        wasm.postFmt(.info, "Submitted {s}!", .{word});
    }
}

export fn init() void {
    wasm.initIfNecessary();

    std.log.info("WASM initialized!", .{});
}
