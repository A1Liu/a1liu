const std = @import("std");
const assets = @import("assets");
const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

// 1. which letters have been used overall? (keyboard)
// 2. which puzzles are most solved? (center)
// 3. what are the greens for those puzzles? (center)
// 4. what are the unfound letters for those puzzles? (center)
// 5. what are the historical submissions? (right, put in React)

const WordSubmission = struct {
    word: [5]u8,
};

const Wordle = struct {
    text: [5]u8,
    letters_found: u8,
    places_found: u8,
};

pub const WasmCommand = WordSubmission;
const Letters = std.bit_set.IntegerBitSet(26);

var wordles_left: std.ArrayList(Wordle) = undefined;
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

pub export fn submitWord(l0: u8, l1: u8, l2: u8, l3: u8, l4: u8) void {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

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
    if (!is_wordle and !searchList(&lowercased, assets.wordle_words)) {
        wasm.postFmt(.err, "{s} doesn't exist", .{word});
        return;
    }

    for (word) |letter, idx| {
        found_letters[idx].set(letter - 'A');
    }

    var write_head: u32 = 0;
    var read_head: u32 = 0;

    var solved = std.ArrayList([5]u8).init(temp);

    const arena_len = wordles_left.items.len;

    while (read_head < arena_len) : (read_head += 1) {
        const wordle = &wordles_left.items[read_head];
        wordle.places_found = 0;
        wordle.letters_found = 0;

        var is_taken: [5]bool = [_]bool{false} ** 5;

        for (wordle.text) |c, idx| {
            if (found_letters[idx].isSet(c - 'a')) {
                wordle.letters_found += 1;
                wordle.places_found += 1;
                is_taken[idx] = true;
            }
        }

        for (wordle.text) |c, c_idx| {
            if (is_taken[c_idx]) {
                continue;
            }

            for (found_letters) |letters, idx| {
                if (is_taken[idx]) {
                    continue;
                }

                if (letters.isSet(c - 'a')) {
                    wordle.letters_found += 1;
                }
            }
        }

        // wordle is done, so we don't write it
        if (wordle.places_found >= 5) {
            solved.append(wordle.text) catch @panic("failed to append to arraylist");
            continue;
        }

        // write would be no-op
        if (read_head == write_head) {
            write_head += 1;
            continue;
        }

        wordles_left.items[write_head] = wordle.*;
        write_head += 1;
    }

    wordles_left.items.len = write_head;

    std.sort.insertionSort(Wordle, wordles_left.items, {}, compareWordles);

    for (solved.items) |solved_word| {
        wasm.postFmt(.info, "solved {s}", .{solved_word});
    }

    wasm.postFmt(.info, "{s} solved {}", .{ word, solved.items.len });

    if (wordles_left.items.len > 0) {
        wasm.postFmt(.info, "{} words left", .{wordles_left.items.len});
    } else {
        wasm.postFmt(.success, "done!", .{});
    }
}

fn compareWordles(context: void, left: Wordle, right: Wordle) bool {
    _ = context;

    if (left.places_found > right.places_found) {
        return true;
    }

    if (left.letters_found > right.letters_found) {
        return true;
    }

    return false;
}

pub export fn init() void {
    wasm.initIfNecessary();

    wordles_left = std.ArrayList(Wordle).init(liu.Pages);

    const wordles = assets.wordles;

    const wordle_count = (wordles.len - 1) / 6 + 1;
    wordles_left.ensureUnusedCapacity(wordle_count) catch
        @panic("failed to allocate room for wordles");

    var word_index: u32 = 0;
    while ((word_index + 5) < wordles.len) : (word_index += 6) {
        var wordle = Wordle{
            .text = undefined,
            .letters_found = 0,
            .places_found = 0,
        };

        std.mem.copy(u8, &wordle.text, wordles[word_index..(word_index + 5)]);
        wordles_left.appendAssumeCapacity(wordle);
    }

    std.log.info("WASM initialized!", .{});
}
