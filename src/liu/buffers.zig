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

            const resizeAssumeEmpty = @compileError("this method is only available " ++
                "for dynamically sized RingBuffer values");

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

const LruConst = struct {
    const MAX = std.math.maxInt(u32);
    const TOMBSTONE = MAX;
    const EMPTY = MAX - 1;

    const LNode = struct {
        next: u32,
        prev: u32,
        hash: u64,

        fn debug(node: *const LNode, idx: u32) void {
            if (node.next == EMPTY) {
                std.debug.print("{}: EMPTY\n", .{idx});
            } else if (node.next == TOMBSTONE) {
                std.debug.print("{}: TOMB \n", .{idx});
            } else {
                std.debug.print("{}: hash: {} {}<- ->{} \n", .{
                    idx,
                    node.hash,
                    node.prev,
                    node.next,
                });
            }
        }
    };
};

pub fn LRU(comptime V: type) type {
    const TOMBSTONE = LruConst.TOMBSTONE;
    const EMPTY = LruConst.EMPTY;
    const LNode = LruConst.LNode;

    // Uses circular doubly linked list to store implicit LRU statuses
    return struct {
        last: u32 = undefined,
        len: u32 = 0,
        capacity: u32,
        meta: [*]LNode,
        values: [*]V,

        const Self = @This();

        const alignment = std.math.max(@alignOf(V), @alignOf(LNode));

        fn allocSize(size: u32) usize {
            const unaligned = size * (@sizeOf(V) + @sizeOf(LNode));
            return mem.alignForward(unaligned, alignment);
        }

        pub fn init(alloc: Allocator, size: u32) !Self {
            if (size >= EMPTY or size == 0) return error.InvalidParam;

            const byte_size = allocSize(size);
            const data = try alloc.alignedAlloc(u8, alignment, byte_size);

            const unaligned_values = @ptrToInt(data.ptr) + (size * @sizeOf(LNode));
            const values = mem.alignForward(unaligned_values, alignment);

            var self = Self{
                .meta = @ptrCast([*]LNode, data.ptr),
                .values = @intToPtr([*]V, values),
                .capacity = size,
            };

            self.clear();

            return self;
        }

        pub fn deinit(self: *Self, alloc: Allocator) void {
            var bytes: []u8 = &.{};
            bytes.ptr = @ptrCast([*]u8, self.meta);
            bytes.len = allocSize(self.capacity);

            alloc.free(bytes);
        }

        pub fn clear(self: *Self) void {
            for (self._meta()) |*slot| slot.next = EMPTY;
            self.len = 0;
        }

        fn _meta(self: *const Self) []LNode {
            var meta: []LNode = &.{};
            meta.ptr = self.meta;
            meta.len = self.capacity;

            return meta;
        }

        fn _values(self: *const Self) []V {
            var values: []V = &.{};
            values.ptr = self.values;
            values.len = self.capacity;

            return values;
        }

        fn search(self: *const Self, hash: u64) ?u32 {
            if (self.len == 0) return null;

            var index = @truncate(u32, hash % self.capacity);

            const meta = self._meta();

            var count: u32 = 0;
            while (count < self.capacity) : (count += 1) {
                const node = &meta[index];

                if (node.next == EMPTY) return null;
                if (node.next != TOMBSTONE and node.hash == hash) return index;

                index += 1;
                if (index >= self.capacity) index = 0;
            }

            return null;
        }

        fn removeNodeFromChain(self: *Self, index: u32) *LNode {
            const meta = self._meta();

            const node = &meta[index];
            const prev = &meta[node.prev];
            const next = &meta[node.next];

            prev.next = node.next;
            next.prev = node.prev;

            if (index == self.last) {
                self.last = node.prev;
            }

            return node;
        }

        fn addNodeToEndOfChain(self: *Self, index: u32) void {
            const meta = self._meta();

            const slot = &meta[index];
            const last = &meta[self.last];
            const first = &meta[last.next];

            slot.prev = self.last;
            slot.next = last.next;

            last.next = index;
            first.prev = index;
            self.last = index;
        }

        pub fn read(self: *Self, hash: u64) ?*V {
            const index = self.search(hash) orelse return null;

            _ = self.removeNodeFromChain(index);
            self.addNodeToEndOfChain(index);

            const values = self._values();
            return &values[index];
        }

        pub fn remove(self: *Self, hash: u64) ?V {
            const index = self.search(hash) orelse return null;

            const values = self._values();

            const node = self.removeNodeFromChain(index);
            node.next = TOMBSTONE;
            self.len -= 1;

            return values[index];
        }

        pub fn insert(self: *Self, hash: u64, value: V) ?V {
            const meta = self._meta();
            const values = self._values();

            var index = @truncate(u32, hash % self.capacity);

            if (self.len == 0) {
                const node = &meta[index];

                self.last = index;
                node.next = index;
                node.prev = index;

                self.len += 1;
                node.hash = hash;
                values[index] = value;

                return null;
            }

            var previous: ?V = null;

            const slot = slot: {
                var count: u32 = 0;
                while (count < self.capacity) : (count += 1) {
                    const node = &meta[index];

                    const empty_slot = node.next == TOMBSTONE or node.next == EMPTY;
                    if (empty_slot) {
                        self.len += 1;
                        break :slot node;
                    }

                    if (node.hash == hash) {
                        _ = self.removeNodeFromChain(index);
                        previous = values[index];

                        break :slot node;
                    }

                    index += 1;
                    if (index >= self.capacity) index = 0;
                }

                // LRU stuff
                const last = &meta[self.last];
                index = last.next;

                const first = self.removeNodeFromChain(index);
                previous = values[index];

                break :slot first;
            };

            self.addNodeToEndOfChain(index);

            slot.hash = hash;
            values[index] = value;

            return previous;
        }
    };
}

const ArrayList2dRange = struct {
    start: u32,
    len: u32,
    capa: u32,
};

pub fn ArrayList2d(comptime T: type, comptime min_capa: ?u32) type {
    return struct {
        bytes: std.ArrayListUnmanaged(T) = .{},
        ranges: std.ArrayListUnmanaged(ArrayList2dRange) = .{},
        used_space: u32 = 0,

        const Self = @This();

        pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
            self.bytes.deinit(alloc);
            self.ranges.deinit(alloc);
        }

        pub fn get(self: *const Self, id: u32) ?[]T {
            if (id >= self.ranges.items.len) return null;

            const range = self.ranges.items[id];
            return self.bytes.items[range.start..][0..range.len];
        }

        pub fn appendFor(self: *Self, alloc: std.mem.Allocator, id: u32, t: T) !void {
            if (id >= self.ranges.items.len) return;

            const range = &self.ranges.items[id];

            if (range.capa == range.len) {
                const addl_capa = range.capa / 2 + 8;
                const new_capa = range.capa + addl_capa;

                try self.ensureUnusedCapacity(alloc, new_capa);

                const start = self.bytes.items.len;
                try self.bytes.ensureUnusedCapacity(alloc, new_capa);

                self.bytes.items.len += new_capa;
                self.used_space += addl_capa;

                const new_slice = self.bytes.items[start..][0..range.len];
                const old_slice = self.bytes.items[range.start..][0..range.len];
                std.mem.copy(T, new_slice, old_slice);

                range.start = @intCast(u32, start);
                range.capa = new_capa;
            }

            self.bytes.items[range.start + range.len] = t;
            range.len += 1;
        }

        pub fn delete(self: *Self, id: u32) void {
            if (id >= self.ranges.items.len) return;

            const range = &self.ranges.items[id];

            self.used_space -= range.capa;
            range.capa = 0;
            range.len = 0;
        }

        pub fn add(self: *Self, alloc: std.mem.Allocator, data: []const T) !u32 {
            const id = try self.allocFor(alloc, @intCast(u32, data.len));
            const slot = self.get(id).?;

            std.mem.copy(T, slot, data);

            return id;
        }

        pub fn ensureUnusedCapacity(self: *Self, alloc: std.mem.Allocator, capacity: u32) !void {
            if (self.bytes.items.len + capacity > self.bytes.capacity) {
                const needed_capacity = std.math.max(self.used_space + capacity, self.bytes.capacity);
                var new_data = std.ArrayListUnmanaged(T){};
                try new_data.ensureTotalCapacity(alloc, needed_capacity);

                for (self.ranges.items) |*range| {
                    const new_start = new_data.items.len;
                    new_data.appendSliceAssumeCapacity(self.bytes.items[range.start..][0..range.capa]);

                    range.start = @intCast(u32, new_start);
                }

                self.bytes.deinit(alloc);
                self.bytes = new_data;
            }
        }

        pub fn allocFor(self: *Self, alloc: std.mem.Allocator, size: u32) !u32 {
            var capacity = min_capa orelse 8;
            while (true) {
                capacity += capacity / 2 + 8;
                if (capacity >= size) break;
            }

            try self.ensureUnusedCapacity(alloc, capacity);

            const id = @intCast(u32, self.ranges.items.len);
            _ = try self.ranges.addOne(alloc);

            const start = self.bytes.items.len;

            // try self.bytes.ensureUnusedCapacity(alloc, capacity);
            assert(self.bytes.items.len + capacity <= self.bytes.capacity);
            self.bytes.items.len += capacity;
            self.used_space += capacity;

            const range = &self.ranges.items[id];
            range.start = @intCast(u32, start);
            range.len = size;
            range.capa = capacity;

            return id;
        }
    };
}

pub const StringTable = struct {
    bytes: std.ArrayListUnmanaged(u8) = .{},
    ranges: std.ArrayListUnmanaged(struct { start: i32, end: u32 }) = .{},

    // use `start` field as next field in freelist
    next_free: ?i32 = null,

    // TODO: do garbage collection instead of only ever increasing
    used_space: u32 = 0,

    const Self = @This();

    pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        self.bytes.deinit(alloc);
        self.ranges.deinit(alloc);
    }

    pub fn get(self: *const Self, id: u32) ?[]const u8 {
        if (id >= self.ranges.items.len) return null;

        const range = self.ranges.items[id];
        if (range.start < 0) return null;

        return self.bytes.items[@intCast(u32, range.start)..range.end];
    }

    pub fn delete(self: *Self, id: u32) void {
        if (id >= self.ranges.items.len) return;

        const id_neg = -@intCast(i32, id) - 1;
        const range = &self.ranges.items[id];
        if (range.start < 0) return;

        self.used_space -= range.end - @intCast(u32, range.start);

        range.start = self.next_free orelse id_neg;
        self.next_free = id_neg;
    }

    pub fn add(self: *Self, alloc: std.mem.Allocator, data: []const u8) !u32 {
        const id = id: {
            if (self.next_free) |id_neg| {
                const id = @intCast(u32, -(id_neg + 1));

                if (self.ranges.items[id].start == id_neg) {
                    self.next_free = null;
                } else {
                    self.next_free = self.ranges.items[id].start;
                }

                break :id id;
            } else {
                const id = @intCast(u32, self.ranges.items.len);

                _ = try self.ranges.addOne(alloc);

                break :id id;
            }
        };

        if (self.bytes.items.len + data.len > self.bytes.capacity) {
            const needed_capacity = self.used_space + data.len;
            var new_data = std.ArrayListUnmanaged(u8){};
            try new_data.ensureTotalCapacity(alloc, needed_capacity);

            for (self.ranges.items) |*range| {
                if (range.start < 0) continue;

                const start = @intCast(u32, range.start);
                const new_start = new_data.items.len;
                new_data.appendSliceAssumeCapacity(self.bytes.items[start..range.end]);
                range.start = @intCast(i32, new_start);
                range.end = @intCast(u32, new_data.items.len);
            }

            self.bytes.deinit(alloc);
            self.bytes = new_data;
        }

        const start = self.bytes.items.len;

        try self.bytes.appendSlice(alloc, data);
        self.used_space += @intCast(u32, data.len);

        const range = &self.ranges.items[id];
        range.start = @intCast(i32, start);
        range.end = @intCast(u32, self.bytes.items.len);

        return id;
    }
};

test "LRU: ordering" {
    const liu = @import("./lib.zig");

    var lru = try LRU(u32).init(liu.Pages, 100);
    defer lru.deinit(liu.Pages);

    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const res = lru.insert(i, i + 1);
        try std.testing.expect(res == null);
    }

    i = 0;

    while (i < 100) : (i += 2) {
        const res = lru.remove(i);
        try std.testing.expect(res == i + 1);
    }

    i = 0;

    while (i < 100) : (i += 1) {
        const res = lru.read(i);

        if (@mod(i, 2) == 0) {
            try std.testing.expect(res == null);
        } else if (res) |r| {
            try std.testing.expect(r.* == i + 1);
        } else {
            try std.testing.expect(false);
        }
    }

    i = 0;

    while (i < 100) : (i += 2) {
        const res = lru.insert(i, i + 1);
        try std.testing.expect(res == null);
    }

    i = 1;
    while (i < 100) : (i += 2) {
        const res = lru.insert(i + 100, i + 1);

        try std.testing.expect(res == i + 1);
    }

    i = 0;
    while (i < 100) : (i += 2) {
        const res = lru.insert(i + 100, i + 1);

        try std.testing.expect(res == i + 1);
    }

    try std.testing.expect(lru.len == 100);

    i = 1;
    while (i < 100) : (i += 2) {
        const res = lru.remove(i + 100);

        try std.testing.expect(res == i + 1);
    }

    try std.testing.expect(lru.len == 50);

    i = 0;
    while (i < 100) : (i += 2) {
        const res = lru.remove(i + 100);

        try std.testing.expect(res == i + 1);
    }

    try std.testing.expect(lru.len == 0);
}
