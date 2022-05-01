const std = @import("std");
const assets = @import("assets");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;

const ext = struct {
    extern fn setPuzzles(obj: wasm.Obj) void;
    extern fn setWordsLeft(count: usize) void;
};

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
const Puzzle = struct {
    solution: [5]u8,
    filled: [5]u8,
    submits: []u8,
};

var wordles_left: ArrayList(Wordle) = undefined;
var found_letters: [5]Letters = [_]Letters{Letters.initEmpty()} ** 5;
var submissions: ArrayList([5]u8) = undefined;

fn setWordsLeft(count: usize) void {
    if (builtin.target.cpu.arch != .wasm32) return;

    ext.setWordsLeft(count);
}

fn setPuzzles(puzzles: []Puzzle) void {
    if (builtin.target.cpu.arch != .wasm32) return;

    const mark = wasm.watermarkObj();
    defer wasm.clearObjBufferForObjAndAfter(mark);

    const arr = wasm.makeArray();
    const solution_key = wasm.stringObj("solution");
    const filled_key = wasm.stringObj("filled");
    const submits_key = wasm.stringObj("submits");

    for (puzzles) |puzzle| {
        const obj = wasm.makeObj();

        const solution = wasm.stringObj(&puzzle.solution);
        const filled = wasm.stringObj(&puzzle.filled);
        const submits = wasm.stringObj(puzzle.submits);

        wasm.objSet(obj, solution_key, solution);
        wasm.objSet(obj, filled_key, filled);
        wasm.objSet(obj, submits_key, submits);

        wasm.arrayPush(arr, obj);
    }

    ext.setPuzzles(arr);
}

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

// Returns array of matches. Value v at index i is a match between wordle[i]
// and submission[v], or null if that match doesn't exist.
fn matchWordle(wordle: [5]u8, submission: [5]u8) [5]?u8 {
    var text = submission;
    var match = [_]?u8{null} ** 5;

    for (wordle) |c, idx| {
        if (submission[idx] == c) {
            match[idx] = @truncate(u8, idx);
            text[idx] = 0;
        }
    }

    for (wordle) |c, idx| {
        if (match[idx] != null) {
            continue;
        }

        for (text) |*slot, text_idx| {
            if (slot.* == c) {
                match[idx] = @truncate(u8, text_idx);
                slot.* = 0;
            }
        }
    }

    return match;
}

pub export fn submitWord(l0: u8, l1: u8, l2: u8, l3: u8, l4: u8) bool {
    var _temp = liu.Temp.init();
    const temp = _temp.allocator();
    defer _temp.deinit();

    const word = [_]u8{ l0, l1, l2, l3, l4 };

    // lowercase
    for (word) |letter| {
        if (letter < 'a' or letter > 'z') {
            wasm.postFmt(.err, "invalid string {s}", .{word});
            return false;
        }
    }

    const is_wordle = searchList(&word, assets.wordles);
    if (!is_wordle and !searchList(&word, assets.wordle_words)) {
        wasm.postFmt(.err, "{s} doesn't exist", .{word});
        return false;
    }

    submissions.append(word) catch @panic("failed to save submission");

    for (word) |letter, idx| {
        found_letters[idx].set(letter - 'a');
    }

    var write_head: u32 = 0;
    var read_head: u32 = 0;
    var solved = ArrayList([5]u8).init(temp);
    const arena_len = wordles_left.items.len;

    while (read_head < arena_len) : (read_head += 1) {
        const wordle = &wordles_left.items[read_head];
        wordle.places_found = 0;
        wordle.letters_found = 0;

        var is_taken: [5]bool = [_]bool{false} ** 5;

        // Exact matches (position + letter)
        for (wordle.text) |c, idx| {
            if (found_letters[idx].isSet(c - 'a')) {
                wordle.letters_found += 1;
                wordle.places_found += 1;
                is_taken[idx] = true;
            }
        }

        // Matches for just letter
        for (wordle.text) |c, c_idx| {
            if (is_taken[c_idx]) {
                continue;
            }

            for (found_letters) |letters, idx| {
                if (is_taken[idx] and c == wordle.text[idx]) {
                    // We've already used this letter in this spot for an exact
                    // match, so let's skip it here
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

    std.sort.sort(Wordle, wordles_left.items, {}, compareWordles);

    const top_count = std.math.min(wordles_left.items.len, 32);
    var puzzles = ArrayList(Puzzle).init(temp);
    for (wordles_left.items[0..top_count]) |wordle| {
        var relevant_submits = ArrayList(u8).init(temp);
        var filled = [_]u8{' '} ** 5;
        var match = [_]?u8{null} ** 5;

        var found: u32 = 0;
        for (wordle.text) |c, idx| {
            const letter_index = c - 'a';
            if (found_letters[idx].isSet(letter_index)) {
                filled[idx] = c;
                match[idx] = @truncate(u8, idx);
                found += 1;
                continue;
            }
        }

        for (submissions.items) |submit| {
            if (found >= 5) {
                break;
            }

            const found_before = found;
            var submit_letters = submit;
            const new_match = matchWordle(wordle.text, submit);
            for (match) |*slot, idx| {
                if (slot.* != null) {
                    continue;
                }

                if (new_match[idx]) |submit_idx| {
                    submit_letters[submit_idx] = submit[submit_idx] - 'a' + 'A';
                    slot.* = submit_idx;
                    found += 1;
                }
            }

            if (found_before < found) {
                relevant_submits.appendSlice(&submit_letters) catch
                    @panic("failed to append submission");
                relevant_submits.append(',') catch
                    @panic("failed to append submission");
            }
        }

        if (relevant_submits.items.len > 0) {
            _ = relevant_submits.pop();
        }

        const err = puzzles.append(.{
            .solution = wordle.text,
            .filled = filled,
            .submits = relevant_submits.items,
        });
        err catch @panic("failed to add puzzle");
    }

    setPuzzles(puzzles.items);
    setWordsLeft(wordles_left.items.len);

    return true;
}

fn compareWordles(context: void, left: Wordle, right: Wordle) bool {
    _ = context;

    if (left.places_found != right.places_found) {
        return left.places_found > right.places_found;
    }

    if (left.letters_found != right.letters_found) {
        return left.letters_found > right.letters_found;
    }

    return false;
}

pub export fn init() void {
    wasm.initIfNecessary();

    wordles_left = ArrayList(Wordle).init(liu.Pages);
    submissions = ArrayList([5]u8).init(liu.Pages);

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

    setWordsLeft(wordles_left.items.len);
    std.log.info("WASM initialized!", .{});
}
