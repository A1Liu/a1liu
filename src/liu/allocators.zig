const std = @import("std");
const root = @import("root");

const mem = std.mem;

const assert = std.debug.assert;

const Allocator = mem.Allocator;
// const ArrayList = std.ArrayList;
const ByteList = std.ArrayListAlignedUnmanaged([]u8, null);
const GlobalAlloc = std.heap.GeneralPurposeAllocator(.{});

// general purpose global allocator for small allocations
var GlobalAllocator: GlobalAlloc = .{};
pub const Alloc = GlobalAllocator.allocator();
pub const Pages = std.heap.page_allocator;

const BumpState = struct {
    const Self = @This();

    ranges: ByteList,
    next_size: usize,

    fn init(initial_size: usize) Self {
        return .{
            .ranges = ByteList{},
            .next_size = initial_size,
        };
    }

    fn allocate(bump: *Self, mark: *Mark, alloc: Allocator, len: usize, ptr_align: u29, ret_addr: usize) Allocator.Error![]u8 {
        if (mark.range < bump.ranges.items.len) {
            const range = bump.ranges.items[mark.range];

            const addr = @ptrToInt(range.ptr) + mark.index_in_range;
            const adjusted_addr = mem.alignForward(addr, ptr_align);
            const adjusted_index = mark.index_in_range + (adjusted_addr - addr);
            const new_end_index = adjusted_index + len;

            if (new_end_index <= range.len) {
                mark.index_in_range = new_end_index;

                return range[adjusted_index..new_end_index];
            }
        }

        const size = @maximum(len, bump.next_size);

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
        const slice = try alloc.rawAlloc(size, ptr_align, 1, ret_addr);
        try bump.ranges.append(alloc, slice);

        // grow the next arena, but keep it to at most 1GB please
        bump.next_size = size * 3 / 2;
        bump.next_size = @minimum(1024 * 1024 * 1024, bump.next_size);

        mark.range = bump.ranges.items.len - 1;
        mark.index_in_range = len;

        return slice[0..len];
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
        const resize = Allocator.NoResize(Self).noResize;
        const free = Allocator.NoOpFree(Self).noOpFree;

        return Allocator.init(self, Self.allocate, resize, free);
    }

    fn allocate(
        self: *Self,
        len: usize,
        ptr_align: u29,
        len_align: u29,
        ret_addr: usize,
    ) Allocator.Error![]u8 {
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
    const InitialSize = if (@hasDecl(root, "liu_TempAlloc_InitialSize"))
        root.liu_TempAlloc_InitialSize
    else
        256 * 1024;

    threadlocal var bump = BumpState.init(InitialSize);

    const allocator = Allocator.init(@intToPtr(*anyopaque, 1), alloc, resize, free);

    const resize = Allocator.NoResize(anyopaque).noResize;
    const free = Allocator.NoOpFree(anyopaque).noOpFree;

    fn alloc(
        _: *anyopaque,
        len: usize,
        ptr_align: u29,
        len_align: u29,
        ret_addr: usize,
    ) Allocator.Error![]u8 {
        _ = len_align;

        return bump.allocate(&TempMark, Pages, len, ptr_align, ret_addr);
    }
};

const SlabAlloc = struct {};

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

// test "Slab" {
//     try SlabAlloc.globalInit();
//     slabFrameBoundary();
// }
