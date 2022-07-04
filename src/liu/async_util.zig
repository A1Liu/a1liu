const std = @import("std");
const liu = @import("./lib.zig");

// I read the things below; none of them helped here. I was very confused,
// and then randomly realized that the 'copy elision slot' from the "coroutine
// rewrite issue" below could be the way that the code from the example at
// the end of Ziglearn is able to figure out where the `resume` should jump
// to. This means that in this code:
//
// output_slot = async read_big_file();
//
// The lifetime of `output_slot` determines the lifetime of the variables in
// the async code; if I instead do
//
// const output_slot = async read_big_file();
//
// This would break things, because output_slot might die before `read_file`
// completes. This seems fucky, and confusing, but empirically, all of the
// following examples cause code breakage in confusing ways:
//
// const output_slot = async read_big_file();
//
// -------------
//
// const temp = async read_big_file();
// output_slot = temp;
//
// -------------
//
// _ = async read_big_file();
//
// I am no more happy or confident in my understanding, because I'm still
// unsure this mental model is true, but the code does work now, so whatever.
//
// Ziglearn: Zig Async -
//      https://ziglearn.org/chapter-5/
// Zigtastic Async (reading x86 output) -
//      https://iamgweej.github.io/jekyll/update/2020/07/07/zigtastic-async.html
// The Coroutine Rewrite Issue -
//      https://github.com/ziglang/zig/issues/2377
// Zig standard library Event Loop source -
//      https://github.com/ziglang/zig/blob/master/lib/std/event/loop.zig
// Someone's implementation - completely-broken
//      https://github.com/creationix/zig-wasm-async
// Someone's implementation - largely unhelpful in understanding what's going on
//      https://github.com/leroycep/zig-wasm-assets
//
//                              - Albert Liu, Jul 02, 2022 Sat 18:18 PDT

// Another important tidbit: `anyframe` is not a frame, but a pointer to a
// frame.
pub const CancelToken = enum(i32) { unbounded, _ };

fn FrameSlot(comptime func: anytype) type {
    return struct {
        slot: *@Frame(func),
        token: CancelToken,
    };
}

var frame_bytes = liu.Bump.init(1024, liu.Pages);

pub fn frameSlot(comptime func: anytype) !FrameSlot(func) {
    const slot = try frame_bytes.allocator().create(@Frame(func));

    return FrameSlot(func){
        .slot = slot,
        .token = .unbounded,
    };
}
