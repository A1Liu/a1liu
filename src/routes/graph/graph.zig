const std = @import("std");
const liu = @import("liu");

var frames: std.ArrayList(anyframe) = std.ArrayList(anyframe).init(liu.Pages);

const wasm = liu.wasm;
pub usingnamespace wasm;

const FrameInput = liu.gamescreen.FrameInput;

// start with async/promise support

const ext = struct {
    extern fn fetch(obj: wasm.Obj) wasm.Obj;
    extern fn awaitHook(obj: wasm.Obj, out: wasm.Obj, frame: u32) void;
};

fn awaitPromise(obj: wasm.Obj) wasm.Obj {
    const output = wasm.make.obj(.manual);

    suspend {
        const frame = @as(anyframe, @frame());
        const id = frames.items.len;
        frames.appendAssumeCapacity(frame);

        ext.awaitHook(obj, output, @truncate(u32, id));
    }

    return output;
}

export fn resumePromise(val: u32) void {
    wasm.post(.log, "resumed", .{});
    resume frames.items[val];
}

fn awaitTheGuy() void {
    const mark = wasm.watermark();
    defer wasm.setWatermark(mark);

    const url = wasm.make.string(.temp, "https://a1liu.com");
    const res = ext.fetch(url);
    _ = await async awaitPromise(res);

    wasm.post(.log, "Done!", .{});
}

export fn init() void {
    liu.gamescreen.init(0);
    frames.ensureUnusedCapacity(16) catch unreachable;

    var frame = async awaitTheGuy();
    nosuspend await frame;

    wasm.post(.log, "init done", .{});
}
