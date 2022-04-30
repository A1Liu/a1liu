const std = @import("std");
const assets = @import("assets");
const liu = @import("liu");

const wasm = liu.wasm;
usingnamespace wasm;

const WordSubmission = struct {
    word: [5]u8,
};

pub const WasmCommand = WordSubmission;

export fn submitWord(l0: u8, l1: u8, l2: u8, l3: u8, l4: u8) void {
    const word = &[_]u8{ l0, l1, l2, l3, l4 };
    _ = word;

    if (std.mem.eql(u8, word, "BLUEY")) {
        std.log.info("Blue!", .{});
    } else if (std.mem.eql(u8, word, "REDDY")) {
        std.log.err("Red!", .{});
    } else if (std.mem.eql(u8, word, "TANGY")) {
        std.log.warn("Orange!", .{});
    } else if (std.mem.eql(u8, word, "GREEN")) {
        wasm.postFmt(.success, "Green!", .{});
    } else {
        std.log.debug("Submitted {s}!", .{word});
    }
}

export fn init() void {
    wasm.initIfNecessary();

    std.log.info("WASM initialized!", .{});
}
