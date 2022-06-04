const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;

const ext = struct {
    extern fn setPuzzles(obj: wasm.Obj) void;
    extern fn setWordsLeft(count: usize) void;
    extern fn addChar(code: u32) void;
    extern fn incrementSubmissionCount() void;
    extern fn resetSubmission() void;

    fn submitWordExt(l0: u8, l1: u8, l2: u8, l3: u8, l4: u8) callconv(.C) bool {
        return submitWord([_]u8{ l0, l1, l2, l3, l4 }) catch @panic("submitWord failed");
    }

    fn initExt(l_wordles: wasm.Obj, l_words: wasm.Obj) callconv(.C) void {
        init(l_wordles, l_words) catch @panic("init failed");
    }
};

// I think this needs to be in root. I tried moving it inside `ext` and most of
// the code got deleted.
comptime {
    @export(ext.initExt, .{ .name = "init", .linkage = .Strong });
    @export(ext.submitWordExt, .{ .name = "submitWord", .linkage = .Strong });
}

const Wordle = struct {
    text: [5]u8,
    matches: [5]Match,
    letters_found: u8,
    places_found: u8,
};

const Puzzle = struct {
    solution: [5]u8,
    filled: [5]u8,
    submits: []u8,
};

// The values matter here, because we use the enum value for an ordered
// comparison later on in the file
const MatchKind = enum(u8) { none = 0, letter = 1, exact = 2 };
const Match = union(MatchKind) {
    none: void,
    exact: void,
    letter: u8,
};

const Keys = struct {
    solution: wasm.Obj,
    filled: wasm.Obj,
    submits: wasm.Obj,
};

// Initialized at start of program
var wordles: []const u8 = undefined;
var wordle_words: []const u8 = undefined;
var keys: Keys = undefined;

var wordles_left: ArrayList(Wordle) = undefined;
var submissions: ArrayList([5]u8) = undefined;

fn makeKeys() Keys {
    return .{
        .solution = wasm.out.string("solution"),
        .filled = wasm.out.string("filled"),
        .submits = wasm.out.string("submits"),
    };
}

fn setPuzzles(puzzles: []Puzzle) void {
    const mark = wasm.watermark();
    defer wasm.setWatermark(mark);

    const arr = wasm.out.array();

    for (puzzles) |puzzle| {
        const obj = wasm.out.obj();

        const solution = wasm.out.string(&puzzle.solution);
        const filled = wasm.out.string(&puzzle.filled);
        const submits = wasm.out.string(puzzle.submits);

        obj.objSet(keys.solution, solution);
        obj.objSet(keys.filled, filled);
        obj.objSet(keys.submits, submits);

        arr.arrayPush(obj);
    }

    ext.setPuzzles(arr);
}

fn searchList(word: [5]u8, dict: []const u8) bool {
    var word_index: u32 = 0;
    while (word_index < dict.len) : (word_index += 6) {
        const dict_slice = dict[word_index..][0..5];

        if (std.mem.eql(u8, &word, dict_slice)) {
            return true;
        }
    }

    return false;
}

// Returns array of matches. Value v at index i is a match between wordle[i]
// and submission[v], or null if that match doesn't exist.
fn matchWordle(wordle: [5]u8, submission: [5]u8) [5]Match {
    var text = submission;
    var match = [_]Match{.none} ** 5;

    for (wordle) |c, idx| {
        if (submission[idx] == c) {
            match[idx] = .exact;
            text[idx] = 0;
        }
    }

    for (wordle) |c, idx| {
        if (match[idx] == .exact) {
            continue;
        }

        for (text) |*slot, text_idx| {
            if (slot.* == c) {
                match[idx] = .{ .letter = @truncate(u8, text_idx) };
                slot.* = 0;
            }
        }
    }

    return match;
}

pub fn submitWord(word: [5]u8) !bool {
    var mark = liu.TempMark;
    defer liu.TempMark = mark;

    // lowercase
    for (word) |letter| {
        if (letter < 'a' or letter > 'z') {
            wasm.out.post(.err, "invalid string {s}", .{word});
            return false;
        }
    }

    const is_wordle = searchList(word, wordles);
    if (!is_wordle and !searchList(word, wordle_words)) {
        return false;
    }

    try submissions.append(word);

    // We use a buffer that's 1 bigger than what we'll eventually read so
    // that we can add to the end and then sort the whole thing. This strategy
    // also has the benefit that insertion sort is guaranteed linear time
    // over our buffer, since it does one sweep up and then one sweep down.
    const top_count = 32;
    var top_values = try std.BoundedArray(Wordle, top_count + 1).init(0);

    var write_head: u32 = 0;
    var read_head: u32 = 0;
    const arena_len = wordles_left.items.len;
    while (read_head < arena_len) : (read_head += 1) {
        const wordle = &wordles_left.items[read_head];

        const new_matches = matchWordle(wordle.text, word);
        for (new_matches) |new_match, idx| {
            const old_match = wordle.matches[idx];
            if (@enumToInt(old_match) >= @enumToInt(new_match)) continue;

            wordle.matches[idx] = new_match;

            if (old_match == .none) wordle.letters_found += 1;
            if (new_match == .exact) wordle.places_found += 1;
        }

        // wordle is done, so we "delete" it by not writing it back to the buffer
        if (wordle.places_found >= 5) {
            continue;
        }

        try top_values.append(wordle.*);
        std.sort.insertionSort(Wordle, top_values.slice(), {}, compareWordles);
        if (top_values.len > top_count) {
            _ = top_values.pop();
        }

        // write-back would be no-op; this also guarantees that the read and
        // write pointers don't alias, for whatever that's worth
        if (read_head == write_head) {
            write_head += 1;
            continue;
        }

        wordles_left.items[write_head] = wordle.*;
        write_head += 1;
    }

    wordles_left.items.len = write_head;

    var puzzles = ArrayList(Puzzle).init(liu.Temp);
    for (top_values.slice()) |wordle| {
        var relevant_submits = ArrayList(u8).init(liu.Temp);
        var matches = [_]Match{.none} ** 5;

        // This gets displayed in the app; in debug mode, we output the lowercase
        // letter so we can see it in the UI to spot-check math. In release,
        // we don't do that, because tha'd be bad.
        var filled = if (builtin.mode == .Debug) wordle.text else [_]u8{' '} ** 5;

        var found: u32 = 0;
        for (wordle.matches) |match, idx| {
            if (match == .exact) {
                matches[idx] = .exact;
                filled[idx] = wordle.text[idx] - 'a' + 'A';
            }
        }

        for (submissions.items) |submit| {
            if (found >= 5) {
                break;
            }

            const found_before = found;
            var submit_letters = submit;
            const new_matches = matchWordle(wordle.text, submit);
            for (matches) |*slot, idx| {
                switch (slot.*) {
                    .exact => continue,
                    .letter => continue,
                    .none => {},
                }

                switch (new_matches[idx]) {
                    // if we have an exact match, it should have been handled
                    // earlier on when we matched the remaining wordles against
                    // the new submission
                    .exact => unreachable,

                    .none => continue,
                    .letter => |submit_idx| {
                        // Uppercase means the output text should be orange.
                        submit_letters[submit_idx] = submit[submit_idx] - 'a' + 'A';
                        slot.* = .{ .letter = submit_idx };
                        found += 1;
                    },
                }
            }

            if (found_before < found) {
                try relevant_submits.appendSlice(&submit_letters);
                try relevant_submits.append(',');
            }
        }

        if (relevant_submits.items.len > 0) {
            _ = relevant_submits.pop();
        }

        try puzzles.append(.{
            .solution = wordle.text,
            .filled = filled,
            .submits = relevant_submits.items,
        });
    }

    setPuzzles(puzzles.items);
    ext.setWordsLeft(wordles_left.items.len);
    ext.resetSubmission();
    ext.incrementSubmissionCount();

    if (builtin.mode != .Debug) return true;

    if (puzzles.items.len == 0) return true;

    for (puzzles.items[0].solution) |c| ext.addChar(c);

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

fn initData() !void {
    const wordle_count = (wordles.len - 1) / 6 + 1;
    try wordles_left.ensureUnusedCapacity(wordle_count);

    var word_index: u32 = 0;
    while ((word_index + 5) < wordles.len) : (word_index += 6) {
        var wordle = Wordle{
            .text = undefined,
            .matches = .{.none} ** 5,
            .letters_found = 0,
            .places_found = 0,
        };

        wordle.text = wordles[word_index..][0..5].*;
        wordles_left.appendAssumeCapacity(wordle);
    }

    ext.setWordsLeft(wordles_left.items.len);
}

export fn reset() void {
    wordles_left.items.len = 0;
    submissions.items.len = 0;

    initData() catch @panic("initData failed");
}

pub fn init(l_wordles: wasm.Obj, l_words: wasm.Obj) !void {
    wasm.initIfNecessary();

    wordles = try wasm.in.bytes(l_wordles, liu.Pages);
    wordle_words = try wasm.in.bytes(l_words, liu.Pages);

    keys = makeKeys();

    wordles_left = ArrayList(Wordle).init(liu.Pages);
    submissions = ArrayList([5]u8).init(liu.Pages);

    try initData();

    std.log.info("WASM initialized!", .{});
}
