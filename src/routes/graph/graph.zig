const std = @import("std");
const liu = @import("liu");

// I read the things below; none of them helped here. I was very confused, and
// then randomly realized that the 'copy-elision' slot from the "coroutine rewrite issue"
// could in fact be the way that the `resume` calls from the
// complete-working-example from the end of Ziglearn is able to jump conceptual
// callframes. Thus, the lifetime of the object you assign the output of `async`
// to is vitally important.
//
// I am no more happy or confident in my understanding, because I'm still unsure
// this mental model is true, but the code does in fact work now, so whatever.
//
// Ziglearn: Zig Async -
//      https://ziglearn.org/chapter-5/
// Zigtastic Async (reading x86 output) -
//      https://iamgweej.github.io/jekyll/update/2020/07/07/zigtastic-async.html
// The Coroutine Rewrite Issue -
//      https://github.com/ziglang/zig/issues/2377
// Zig standard library Event Loop source -
//      https://github.com/ziglang/zig/blob/master/lib/std/event/loop.zig
// Someone's completely-broken implementation -
//      https://github.com/creationix/zig-wasm-async
// Someone's implementation (largely unhelpful in understanding what's going on) -
//      https://github.com/leroycep/zig-wasm-assets
//
//
//
//
//                              - Albert Liu, Jul 02, 2022 Sat 18:18 PDT

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

var whar: @Frame(awaitTheGuy) = undefined;

fn awaitTheGuy() void {
    const mark = wasm.watermark();
    defer wasm.setWatermark(mark);

    const url = wasm.make.string(.temp, "https://a1liu.com");
    const res = ext.fetch(url);
    _ = awaitPromise(res);

    wasm.post(.log, "Done!", .{});
}

export fn init() void {
    liu.gamescreen.init(0);
    frames.ensureUnusedCapacity(16) catch unreachable;

    whar = async awaitTheGuy();

    wasm.post(.log, "init done", .{});
}
