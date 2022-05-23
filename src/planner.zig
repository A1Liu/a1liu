const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

// Planner that understands things
// Step 1: PWA stuffs
// Step 2: Calendar interface, iCal format
// Step 3: Object model, engine v1
// Step 4: Try it out
//
// Collaboration
// - Automerge - https://github.com/automerge/automerge

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

export fn init() void {
    wasm.initIfNecessary();

    wasm.out.post(.info, "WASM initialized!", .{});
}
