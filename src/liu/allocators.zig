const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const assert = std.debug.assert;
const Allocator = mem.Allocator;

// TODO: Track memory used and memory freed

pub const Pages = std.heap.page_allocator;
pub const Bump = std.heap.ArenaAllocator;
pub const Fixed = std.heap.FixedBufferAllocator;
pub const LogPages = LogPagesAllocator.allocator();

var LogPagesAllocator = std.heap.LoggingAllocator(
    std.log.Level.info,
    std.log.Level.warn,
).init(Pages);

// TODO:
// - https://twitter.com/SebAaltonen/status/1616771875413049344
// - https://github.com/mattconte/tlsf

// TODO: This REALLY shouldn't be connected directly to Pages
threadlocal var temp_is_init = false;
threadlocal var current_temp_object: ?*TempState = null;
threadlocal var temp_alloc =
    // std.heap.ArenaAllocator.init(LogPages);
    std.heap.ArenaAllocator.init(Pages);

const TempState = struct {
    bump: *Bump,
    alloc: Allocator,
    prev: ?*@This() = null,

    pub fn deinit(self: *@This()) void {
        const alloc = temp_alloc.allocator();
        self.bump.deinit();
        alloc.destroy(self.bump);
        alloc.destroy(self);

        if (self != current_temp_object) {
            @panic("detected misuse of liu.Temp(): need to call defer temp.deinit() directly after liu.Temp()");
        }

        current_temp_object = self.prev;
    }
};

pub fn Temp() *TempState {
    if (!temp_is_init) {
        // Thread local storage in Zig seems to break at times. This assignment
        // prevents at least 1 bug that surfaces during testing.
        // Tracked here: https://github.com/ziglang/zig/issues/11364
        //
        //                          - Albert Liu, Jan 31, 2023 Tue 23:37
        temp_alloc = std.heap.ArenaAllocator.init(Pages);
        const alloc = temp_alloc.allocator();

        // I wish this didn't have to be eager like this, but I think its
        // the best option for now.
        const ptr = alloc.create([1024]u8) catch
            @panic("failed to pre-allocate to Temporary Allocator");
        alloc.destroy(ptr);
        temp_is_init = true;
    }

    const alloc = temp_alloc.allocator();

    const temp = alloc.create(TempState) catch @panic("failed to create TempState");
    const bump = alloc.create(Bump) catch @panic("failed to create Bump");

    bump.* = Bump.init(alloc);
    temp.* = .{
        .bump = bump,
        .alloc = bump.allocator(),
        .prev = current_temp_object,
    };
    current_temp_object = temp;

    return temp;
}

// This code should cause a panic, but that's not something that can be tested
// right now.
// test "ALLOC: temporary allocator should panic when called incorrectly" {
//     const temp = Temp();
//     defer temp.deinit();
//
//     const hello = struct {
//         fn hello(a: usize) usize {
//             const t = Temp();
//             _ = t;
//
//             return a;
//         }
//     }.hello;
//
//     _ = hello(2);
// }
