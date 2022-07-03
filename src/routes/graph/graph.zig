const std = @import("std");
const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

const FrameInput = liu.gamescreen.FrameInput;

// start with async/promise support

const ext = struct {
    extern fn fetch(obj: wasm.Obj) wasm.Obj;
    extern fn timeout(ms: u32) wasm.Obj;
};

fn awaitTheGuy() void {
    const url = wasm.make.string(.manual, "https://a1liu.com");
    defer url.delete();

    const timeout = ext.timeout(2000);
    defer timeout.delete();

    _ = timeout.Await();

    const res = ext.fetch(url);
    defer res.delete();

    const out = res.Await();
    defer out.delete();

    wasm.post(.log, "Done!", .{});
}

export fn init() void {
    liu.gamescreen.init(0);

    const slot = liu.Pages.create(@Frame(awaitTheGuy)) catch unreachable;
    slot.* = async awaitTheGuy();

    wasm.post(.log, "init done", .{});
}
