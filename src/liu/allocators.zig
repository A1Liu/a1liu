const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const Allocator = mem.Allocator;

pub const Bump = std.heap.ArenaAllocator;
pub const Pages = std.heap.page_allocator;

// TODO:
// - https://twitter.com/SebAaltonen/status/1616771875413049344
// - https://github.com/mattconte/tlsf

threadlocal var TemporaryAllocator = std.heap.ArenaAllocator.init(Pages);

const TempState = struct {
    ptr: *Bump,
    alloc: Allocator,

    pub fn deinit(self: *@This()) void {
        const alloc = TemporaryAllocator.allocator();
        self.ptr.deinit();
        alloc.destroy(self.ptr);
        alloc.destroy(self);
    }
};

pub fn Temp() *TempState {
    const alloc = TemporaryAllocator.allocator();

    const temp = alloc.create(TempState) catch @panic("failed to create TempState");
    const bump = alloc.create(Bump) catch @panic("failed to create Bump");

    bump.* = Bump.init(alloc);
    temp.* = .{
        .ptr = bump,
        .alloc = bump.allocator(),
    };

    return temp;
}
