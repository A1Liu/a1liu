const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");
const assets = @import("assets").kilordle;

const Spec = assets.Spec;

const wasm = liu.wasm;
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

    fn initExt(l_asset: wasm.Obj) callconv(.C) void {
        init(l_asset) catch @panic("init failed");
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
var wordles: [5][]const u8 = undefined;
var wordle_words: [5][]const u8 = undefined;
var keys: Keys = undefined;

var wordles_left: ArrayList(Wordle) = undefined;
var submissions: ArrayList([5]u8) = undefined;

fn makeKeys() Keys {
    return .{
        .solution = wasm.make.string(.manual, "solution"),
        .filled = wasm.make.string(.manual, "filled"),
        .submits = wasm.make.string(.manual, "submits"),
    };
}

fn setPuzzles(puzzles: []Puzzle) void {
    const mark = wasm.watermark();
    defer wasm.setWatermark(mark);

    const arr = wasm.make.array(.temp);

    for (puzzles) |puzzle| {
        const obj = wasm.make.obj(.temp);

        const solution = wasm.make.string(.temp, &puzzle.solution);
        const filled = wasm.make.string(.temp, &puzzle.filled);
        const submits = wasm.make.string(.temp, puzzle.submits);

        obj.objSet(keys.solution, solution);
        obj.objSet(keys.filled, filled);
        obj.objSet(keys.submits, submits);

        arr.arrayPush(obj);
    }

    ext.setPuzzles(arr);
}

// wordle-words: binary search for first 2, linear for last 3
fn searchList(word: [5]u8, dict: [5][]const u8) bool {
    var start: u32 = 0;
    var end: u32 = dict[0].len;

    for (word) |letter, idx| {
        const letter_dict = dict[idx][0..end];

        // find loop
        found: {
            for (letter_dict[start..]) |l, offset| {
                if (l == letter) {
                    start += offset;
                    break :found;
                }
            }

            return false;
        }

        if (idx == 4) return true;
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
            wasm.post(.err, "invalid string {s}", .{word});
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
    const wordle_count = wordles[0].len;

    try wordles_left.ensureUnusedCapacity(wordle_count);

    var i: u32 = 0;
    while (i < wordle_count) : (i += 1) {
        var wordle = Wordle{
            .text = undefined,
            .matches = .{.none} ** 5,
            .letters_found = 0,
            .places_found = 0,
        };

        for (wordle.text) |*slot, idx| {
            slot.* = wordles[idx][i];
        }

        wordles_left.appendAssumeCapacity(wordle);
    }

    ext.setWordsLeft(wordles_left.items.len);
}

export fn reset() void {
    wordles_left.items.len = 0;
    submissions.items.len = 0;

    initData() catch @panic("initData failed");
}

fn initDict(dict: *[5][]const u8, data: []const u8) void {
    const len = data.len / 5 - 1;

    var start: usize = 0;
    var end: usize = len;

    for (dict) |*slot| {
        slot.* = data[start..end];
        start += len + 1;
        end += len + 1;
    }
}

pub fn init(l_asset: wasm.Obj) !void {
    wasm.initIfNecessary();

    const asset_data = try wasm.in.alignedBytes(l_asset, liu.Pages, 8);
    const parsed = try liu.packed_asset.parse(Spec, asset_data);

    wordles[0] = parsed.wordles[0].slice();
    wordles[1] = parsed.wordles[1].slice();
    wordles[2] = parsed.wordles[2].slice();
    wordles[3] = parsed.wordles[3].slice();
    wordles[4] = parsed.wordles[4].slice();

    wordle_words[0] = parsed.words[0].slice();
    wordle_words[1] = parsed.words[1].slice();
    wordle_words[2] = parsed.words[2].slice();
    wordle_words[3] = parsed.words[3].slice();
    wordle_words[4] = parsed.words[4].slice();

    keys = makeKeys();

    wordles_left = ArrayList(Wordle).init(liu.Pages);
    submissions = ArrayList([5]u8).init(liu.Pages);

    try initData();

    // std.log.info("{}", .{wordles[0].len});
    std.log.info("WASM initialized!", .{});
}
