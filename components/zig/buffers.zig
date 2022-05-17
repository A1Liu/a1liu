const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const assert = std.debug.assert;

pub fn RingBuffer(comptime T: type, comptime len_opt: ?usize) type {
    return struct {
        const Self = @This();

        const Cond = if (len_opt) |buffer_len| struct {
            const Buffer = [buffer_len]T;
            const Alloc = void;

            const resizeAssumeEmpty = @compileError("this method is only available for dynamically sized RingBuffer values");

            fn init() Self {
                return Self{
                    .data = undefined,
                    .alloc = {},

                    .next = 0,
                    .last = 0,
                };
            }

            fn deinit(self: *Self) void {
                _ = self;
            }
        } else struct {
            const Buffer = []T;
            const Alloc = Allocator;

            fn init(size: usize, alloc: Allocator) !Self {
                const data = try alloc.allocAdvanced(T, null, size, .at_least);

                return Self{
                    .data = data,
                    .alloc = alloc,

                    .next = 0,
                    .last = 0,
                };
            }

            fn deinit(self: *Self) void {
                self.alloc.free(self.data);
            }

            fn resizeAssumeEmpty(self: *Self, new_len: usize) !void {
                assert(self.isEmpty());

                self.next = 0;
                self.last = 0;

                if (self.alloc.resize(self.data)) |new_slice| {
                    self.data = new_slice;
                }

                // since the container is empty, we can just free previous buffer
                self.alloc.free(self.data);
                self.data = try self.alloc.allocAdvanced(T, null, new_len, .at_least);
            }
        };

        data: Cond.Buffer,
        alloc: Cond.Alloc,
        next: usize,
        last: usize,

        pub const init = Cond.init;
        pub const deinit = Cond.deinit;
        pub const resizeAssumeEmpty = Cond.resizeAssumeEmpty;

        pub fn resetCountersIfEmpty(self: *Self) bool {
            if (self.isEmpty()) {
                self.next = 0;
                self.last = 0;

                return true;
            }

            return false;
        }

        pub fn isEmpty(self: *const Self) bool {
            return self.next == self.last;
        }

        pub fn len(self: *const Self) usize {
            return self.next - self.last;
        }

        pub fn push(self: *Self, t: T) bool {
            return self.pushMany(&.{t}) > 0;
        }

        pub fn pop(self: *Self) ?T {
            var data = [1]T{undefined};

            if (self.popMany(&data).len > 0) {
                return data[0];
            }

            return null;
        }

        pub fn pushMany(self: *Self, data: []const T) usize {
            const end = std.math.min(self.last + self.data.len, self.next + data.len);
            const allocs = circularIndex(self.next, end, &self.data);
            self.next += allocs.len;

            const split_point = allocs.first.len;
            mem.copy(T, allocs.first, data[0..split_point]);
            mem.copy(T, allocs.second, data[split_point..allocs.len]);

            return allocs.len;
        }

        pub fn popMany(self: *Self, data: []T) []T {
            const end = std.math.min(self.next, self.last + data.len);
            const allocs = circularIndex(self.last, end, &self.data);
            self.last += allocs.len;

            const split_point = allocs.first.len;
            mem.copy(T, data[0..split_point], allocs.first);
            mem.copy(T, data[split_point..allocs.len], allocs.second);

            return data[0..allocs.len];
        }

        pub fn allocPush(self: *Self, count: usize) ?[]T {
            const end = std.math.min(self.last + self.data.len, self.next + count);
            const allocs = circularIndex(self.next, end, &self.data);
            if (allocs.len > allocs.first) {
                return null;
            }

            self.next += allocs.len;

            return allocs.first;
        }

        pub const SplitBuffer = struct {
            first: []T = &.{},
            second: []T = &.{},
            len: usize = 0,
        };

        fn circularIndex(begin: usize, end: usize, data: []T) SplitBuffer {
            assert(begin <= end);

            var out = SplitBuffer{ .len = end - begin };
            assert(out.len <= data.len);

            if (begin == end) {
                return out;
            }

            const begin_idx = begin % data.len;
            const end_idx = end % data.len;

            if (begin_idx < end_idx) {
                out.first = data[begin_idx..end_idx];
            } else {
                out.first = data[begin_idx..data.len];
                out.second = data[0..end_idx];
            }

            assert(out.first.len + out.second.len == out.len);

            return out;
        }
    };
}

test "RingBuffer: capacity safety" {
    const TBuffer = RingBuffer(u8, 16);
    var messages: TBuffer = TBuffer.init();

    var i: u8 = undefined;

    var cap: u32 = 0;
    i = 0;
    while (i < 32) : (i += 1) {
        if (messages.push(i)) {
            cap += 1;
        }
    }

    var popCap: u32 = 0;
    i = 0;
    while (i < 32) : (i += 1) {
        if (messages.pop()) |c| {
            try std.testing.expect(c == i);
            popCap += 1;
        }
    }

    try std.testing.expect(popCap == cap);
}

test "RingBuffer: data integrity" {
    const TBuffer = RingBuffer(u8, 16);
    var messages: TBuffer = TBuffer.init();

    var i: u8 = undefined;

    i = 0;
    while (i < 16) : (i += 1) {
        const success = messages.push(i);
        assert(success);
    }

    i = 0;
    while (i < 8) : (i += 1) {
        if (messages.pop()) |c| {
            try std.testing.expect(c == i);
        }
    }

    i = 0;
    while (i < 8) : (i += 1) {
        const success = messages.push(i + 16);
        assert(success);
    }

    i = 0;
    while (i < 16) : (i += 1) {
        if (messages.pop()) |c| {
            try std.testing.expect(c == i + 8);
        }
    }
}

pub fn LRU(comptime K: type, comptime V: type, comptime hasher: fn (K) u64) type {
    const MAX = std.math.maxInt(u32);
    const TOMBSTONE = MAX;
    const EMPTY = MAX - 1;

    const LNode = struct {
        next: u32,
        prev: u32,
        hash: u64,
    };

    return struct {
        len: u32 = 0,
        last: u32 = undefined,
        meta: *LNode,
        values: *V,
        capacity: u32,

        const Self = @This();

        pub fn init(alloc: Allocator, size: u32) !Self {
            if (size >= EMPTY or size == 0) return error.InvalidParam;

            _ = alloc;

            return error.Overflow;

            // const data = try alloc.alloc(LNode, size);
            // for (data) |*slot| {
            //     slot.next = EMPTY;
            //     slot.prev = EMPTY;
            // }

            // return Self{ .data = data };
        }

        pub fn deinit(self: *Self, alloc: Allocator) void {
            alloc.free(self.data);
        }

        pub fn insert(self: *Self, key: K, value: V) ?V {
            const hash = hasher(key);
            var index = hash % self.data.len;
            var count = 0;

            var previous: ?V = null;

            const slot = slot: {
                if (self.len == 0) {
                    const node = &self.data[index];

                    self.last = index;
                    node.next = index;
                    self.len += 1;

                    break :slot node;
                }

                while (count < self.data.len) : (count += 1) {
                    const node = &self.data[index];
                    if (node.next == TOMBSTONE or node.next == EMPTY) {
                        self.len += 1;
                        break :slot node;
                    }

                    index += 1;
                    if (index > self.data.len) index = 0;
                }

                // LRU stuff

                const first_index = self.data[self.last].next;
                const first = &self.data[first_index];

                previous = first.value;

                break :slot first;
            };

            const last = &self.data[self.last];

            slot.prev = self.last;
            slot.next = last.next;
            slot.hash = hash;
            slot.value = value;

            last.next = index;

            self.last = index;

            return previous;
        }
    };
}

test "LRU: ordering" {
    const liu = @import("./lib.zig");
    const hasher = struct {
        fn hasher(i: u32) u64 {
            return i;
        }
    }.hasher;

    var lru = try LRU(u32, u32, hasher).init(liu.Pages, 100);
    _ = lru;
}
