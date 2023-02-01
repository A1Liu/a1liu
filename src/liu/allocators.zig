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
threadlocal var TemporaryAllocator =
    //     if (builtin.mode == .Debug)
    //     std.heap.ArenaAllocator.init(LogPages)
    // else
    std.heap.ArenaAllocator.init(Pages);

const TempState = struct {
    bump: *Bump,
    alloc: Allocator,

    pub fn deinit(self: *@This()) void {
        const alloc = TemporaryAllocator.allocator();
        self.bump.deinit();
        alloc.destroy(self.bump);
        alloc.destroy(self);
    }
};

pub fn Temp() *TempState {
    const alloc = TemporaryAllocator.allocator();

    // I wish this didn't have to be eager like this, but I think its the best
    // option for now.
    if (!temp_is_init) {
        TemporaryAllocator = std.heap.ArenaAllocator.init(Pages);

        const ptr = alloc.create([1024]u8) catch
            @panic("failed to pre-allocate to Temporary Allocator");
        alloc.destroy(ptr);
        temp_is_init = true;
    }

    const temp = alloc.create(TempState) catch @panic("failed to create TempState");
    const bump = alloc.create(Bump) catch @panic("failed to create Bump");

    bump.* = Bump.init(alloc);
    temp.* = .{
        .bump = bump,
        .alloc = bump.allocator(),
    };

    return temp;
}
