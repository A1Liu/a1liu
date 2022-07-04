const std = @import("std");
const liu = @import("src/liu/lib.zig");

const value_count = 1_000_000;

const freq = 4;
const Alloc = std.heap.c_allocator;
// const Alloc = liu.Pages;

pub fn main() !void {
    var rnd = std.rand.RomuTrio.init(2);

    var values = std.ArrayList(u64).init(Alloc);

    try values.ensureTotalCapacity(value_count);
    var i: u32 = 0;
    while (i < value_count) : (i += 1) {
        const a = rnd.random().int(u64);
        values.appendAssumeCapacity(a);
    }

    var dumb: std.ArrayListUnmanaged(std.ArrayListUnmanaged(u64)) = .{};
    defer {
        for (dumb.items) |*d| {
            d.deinit(Alloc);
        }

        dumb.deinit(Alloc);
    }

    var timer = try std.time.Timer.start();
    {
        try dumb.ensureUnusedCapacity(Alloc, value_count);

        try dumb.append(Alloc, .{});

        for (values.items) |value| {
            const id = value % dumb.items.len;

            if (value % freq == 0) {
                try dumb.append(Alloc, .{});
            } else if (value % freq == 1) {
                dumb.items[id].deinit(Alloc);
                dumb.items[id] = .{};
                continue;
            }

            try dumb.items[id].append(Alloc, value);
        }
    }
    const simple_time = timer.read();

    var meh: liu.ArrayList2d(u64) = .{};
    defer meh.deinit(Alloc);

    timer = try std.time.Timer.start();
    {
        try meh.ensureUnusedCapacity(Alloc, value_count);
        try meh.ensureUnusedCountCapacity(Alloc, value_count);

        _ = try meh.add(Alloc, &.{});

        for (values.items) |value| {
            const id = value % meh.len();

            if (value % freq == 0) {
                _ = try meh.add(Alloc, &.{});
            } else if (value % freq == 1) {
                meh.clear(id);
                continue;
            }

            try meh.appendFor(Alloc, id, value);
        }
    }
    const test_time = timer.read();

    // try std.testing.expectEqual(@as(usize, meh.len()), dumb.items.len);

    std.debug.print("dumb: {:>10}\n  2d: {:>10}\n", .{ simple_time, test_time });
}
