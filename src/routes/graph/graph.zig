const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

const FrameInput = liu.gamescreen.FrameInput;

// start with async/promise support
//
// id swizzle

export fn init() void {
    const input = liu.gamescreen.frameStart(0);
    _ = input;
}
