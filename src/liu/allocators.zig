const std = @import("std");

const mem = std.mem;

const assert = std.debug.assert;

const Allocator = mem.Allocator;

const AllocTracker = struct {
    alloc: Allocator,
    parent: Allocator,
    name: []const u8,
    used_bytes: usize,
    free_bytes: usize,
};

var tracked_allocators = [_]?AllocTracker{null} ** 20;

pub fn trackedAllocator(obj: anytype) Allocator {
    _ = obj;

    unreachable;
}

pub const Pages = std.heap.page_allocator;

const BumpState = struct {
    const Self = @This();

    ranges: std.ArrayListAlignedUnmanaged([]u8, null),
    next_size: usize,

    fn init(initial_size: usize) Self {
        return .{
            .ranges = .{},
            .next_size = initial_size,
        };
    }

    fn allocate(bump: *Self, mark: *Mark, alloc: Allocator, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        if (mark.range < bump.ranges.items.len) {
            const range = bump.ranges.items[mark.range];

            const addr = @ptrToInt(range.ptr) + mark.index_in_range;
            const adjusted_addr = mem.alignForward(addr, ptr_align);
            const adjusted_index = mark.index_in_range + (adjusted_addr - addr);
            const new_end_index = adjusted_index + len;

            if (new_end_index <= range.len) {
                mark.index_in_range = new_end_index;

                return range[adjusted_index..new_end_index].ptr;
            }
        }

        const size = @max(len, bump.next_size);

        // Holy crap if you mess up the alignment, boyo the Zig UB detector
        // will come for you with an assertion failure 10 frames deep into
        // the standard library.
        //
        // In this case, since we're returning exactly the requested length every
        // time, the len_align parameter is 1, so that we can get extra if
        // our parent allocator so deigns it, but we don't care about the alignment
        // we get from them. We still require pointer alignment, so we can
        // safely return the allocation we're given to the caller.
        //
        // https://github.com/ziglang/zig/blob/master/lib/std/mem/Allocator.zig
        const slice = alloc.rawAlloc(size, ptr_align, ret_addr) orelse return null;
        bump.ranges.append(alloc, slice[0..size]) catch return null;

        // grow the next arena, but keep it to at most 1GB please
        bump.next_size = size * 3 / 2;
        bump.next_size = @min(1024 * 1024 * 1024, bump.next_size);

        mark.range = bump.ranges.items.len - 1;
        mark.index_in_range = len;

        return slice;
    }
};

pub const Mark = struct {
    range: usize,
    index_in_range: usize,

    pub const ZERO: @This() = .{ .range = 0, .index_in_range = 0 };
};

pub const Bump = struct {
    const Self = @This();

    bump: BumpState,
    mark: Mark,
    alloc: Allocator,

    pub fn init(initial_size: usize, alloc: Allocator) Self {
        return .{
            .bump = BumpState.init(initial_size),
            .mark = Mark.ZERO,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.ranges.items) |range| {
            self.alloc.free(range);
        }

        self.ranges.deinit(self.alloc);
    }

    fn compareLessThan(context: void, left: []u8, right: []u8) bool {
        _ = context;

        return left.len > right.len;
    }

    pub fn resetAndKeepLargestArena(self: *Self) void {
        const items = self.bump.ranges.items;
        if (items.len == 0) {
            return;
        }

        std.sort.insertionSort([]u8, items, {}, compareLessThan);

        for (items[1..]) |*range| {
            self.alloc.free(range.*);

            range.* = &.{};
        }

        self.bump.ranges.items.len = 1;
        self.mark = Mark.ZERO;
    }

    pub fn allocator(self: *Self) Allocator {
        const resize = Allocator.noResize;
        const free = Allocator.noFree;

        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = Self.allocate,
                .resize = resize,
                .free = free,
            },
        };
    }

    fn allocate(
        self: *Self,
        len: usize,
        ptr_align: u29,
        len_align: u29,
        ret_addr: usize,
    ) ?[]u8 {
        _ = len_align;

        return self.bump.allocate(
            &self.mark,
            self.alloc,
            len,
            ptr_align,
            ret_addr,
        );
    }
};

pub const Temp = TempAlloc.allocator;
pub threadlocal var TempMark: Mark = Mark.ZERO;

const TempAlloc = struct {
    const InitialSize = 256 * 1024;

    threadlocal var bump = BumpState.init(InitialSize);

    const allocator: Allocator = .{
        .ptr = @intToPtr(*anyopaque, 1),
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .free = free,
        },
    };

    const resize = Allocator.noResize;
    const free = Allocator.noFree;

    fn alloc(
        _: *anyopaque,
        len: usize,
        ptr_align: u8,
        ret_addr: usize,
    ) ?[*]u8 {
        return bump.allocate(&TempMark, Pages, len, ptr_align, ret_addr);
    }
};

// TODO: rewrite Pages to be the same on native but to use wasmGrow on webassembly
// TODO: finish this implementation lol

const Slab = struct {
    const NULL = std.math.maxInt(u32);

    const min_arena_size: usize = 1024 * 1024;

    const Header = extern struct {
        prev_size: u32 align(8),
        current: packed struct {
            is_free: bool,
            size: u31,
        },
    };

    const FreeHeader = extern struct {
        header: Header,

        // relative, use header_address - prev_free
        prev_free: u32,

        // relative, use header_address + next_free
        next_free: u32,
    };

    const Arena = extern struct {
        const Self = @This();
        // alignments are always to 8
        //
        // cutoff is 1MB

        // indices start at &arena.first_header, are in bytes

        // next slab data
        next: ?*align(8) Self align(8),

        // Size of data after this slab object
        size: u32,

        // next in free-list; should start out as NULL
        next_free: u32,

        // next in bump list; should start out as 0
        next_bump: u32,

        first_header: Header,

        fn init(size: usize) !*Self {
            if (size >= NULL - @sizeOf(Header)) return error.ArenaSizeTooLarge;

            const arena_size = std.math.max(size, min_arena_size);

            // allocAdvanced
            const chunk_ptr = try Pages.alignedAlloc(u8, 8, @sizeOf(Self) + arena_size);
            const self = @ptrCast(*Self, chunk_ptr.ptr);

            self.next = null;
            self.size = @truncate(u32, arena_size);
            self.next_free = NULL;
            self.next_bump = 0;

            return self;
        }

        fn deinit(self: *const Self) void {
            var bytes: []const u8 = undefined;
            bytes.ptr = @ptrCast([*]const u8, self);
            bytes.len = self.size;

            Pages.free(bytes);
        }

        fn freeHeaderFromIndex(self: *Self, index: u32) ?*FreeHeader {
            if (index == NULL) return null;

            const value = @ptrToInt(&self.first_header) + index;
            const header = @intToPtr(*FreeHeader, value);

            std.debug.assert(header.header.current.is_free);

            return header;
        }

        fn alloc(self: *@This(), len: usize, ptr_align: u29, len_align: u29) ?[]u8 {
            // const self_too_small = len > self.size;

            if (self.freeHeaderFromIndex(self.next_bump)) |header| {
                _ = header;
            }

            // const addr = @ptrToInt(range.ptr) + mark.index_in_range;
            // const adjusted_addr = mem.alignForward(addr, ptr_align);
            // const adjusted_index = mark.index_in_range + (adjusted_addr - addr);
            // const new_end_index = adjusted_index + len;

            _ = len;
            _ = ptr_align;
            _ = len_align;

            // if (self.next_bump +  <  ) {
            // }

            // const nothing_free = self.next_free !=  NULL;
            // if (self_too_small or nothing_free) return null;

        }
    };

    first: *align(8) Arena = undefined,
    current: *align(8) Arena = undefined,

    pub fn alloc(
        self: *@This(),
        len: usize,
        ptr_align: u29,
        ret_addr: usize,
    ) ?[*]u8 {
        if (self.current.alloc(len, ptr_align)) |a| {
            return a;
        }

        return Pages.rawAlloc(len, ptr_align, ret_addr);

        // _ = self;
        // _ = len;
        // _ = ptr_align;
        // _ = len_align;
        // _ = ret_addr;
    }
};

test "Slab" {
    try std.testing.expectEqual(@sizeOf(Slab.Header), 8);
    try std.testing.expectEqual(@alignOf(Slab.Header), 8);
    try std.testing.expectEqual(@sizeOf(Slab.FreeHeader), 16);
    try std.testing.expectEqual(@alignOf(Slab.FreeHeader), 8);
    try std.testing.expectEqual(@alignOf(Slab.Arena), 8);

    const arena = try Slab.Arena.init(0);
    defer arena.deinit();
}

// pub fn slabFrameBoundary() void {
//     if (!std.debug.runtime_safety) return;
//
//     const value = @atomicLoad(u64, &SlabAlloc.next, .SeqCst);
//     SlabAlloc.frame_begin = value;
// }

// const SlabAlloc = struct {
//     // Naughty dog-inspired allocator, takes 2MB chunks from a pool, and its
//     // ownership of chunks does not outlive the frame boundary.
//
//     const SlabCount = if (@hasDecl(root, "liu_SlabAlloc_SlabCount"))
//         root.liu_SlabAlloc_SlabCount
//     else
//         1024;
//
//     const page = [4096]u8;
//
//     var frame_begin: if (std.debug.runtime_safety) ?u64 else void = if (std.debug.runtime_safety)
//         null
//     else {};
//
//     var next: usize = 0;
//     var slab_begin: [*]align(1024) page = undefined;
//
//     pub fn globalInit() !void {
//         assert(next == 0);
//
//         if (std.debug.runtime_safety) {
//             assert(frame_begin == null);
//         }
//
//         const slabs = try Pages.alignedAlloc(page, SlabCount, 1024);
//         slab_begin = slabs.ptr;
//     }
//
//     pub fn getMem() *[4096]u8 {
//         const out = @atomicRmw(u64, &SlabAlloc.next, .Add, 1, .SeqCst);
//
//         if (std.debug.runtime_safety) {
//             if (frame_begin) |begin| {
//                 assert(begin - out < SlabCount);
//             }
//         }
//
//         return &slab_begin[out % SlabCount];
//     }
// };

