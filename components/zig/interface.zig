const std = @import("std");
const mem = std.mem;
const trait = std.meta.trait;

const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// inspiration (and some copying) from https://github.com/alexnask/interface.zig

pub const SelfType = opaque {};

fn makeSelfPtr(ptr: anytype) *SelfType {
    if (comptime !trait.isSingleItemPtr(@TypeOf(ptr))) {
        @compileError("SelfType pointer initialization expects pointer parameter.");
    }

    const T = std.meta.Child(@TypeOf(ptr));

    if (@sizeOf(T) > 0) {
        return @ptrCast(*SelfType, ptr);
    } else {
        return undefined;
    }
}

fn selfPtrAs(self: *SelfType, comptime T: type) *T {
    if (@sizeOf(T) > 0) {
        return @alignCast(@alignOf(T), @ptrCast(*align(1) T, self));
    } else {
        return undefined;
    }
}

fn constSelfPtrAs(self: *const SelfType, comptime T: type) *const T {
    if (@sizeOf(T) > 0) {
        return @alignCast(@alignOf(T), @ptrCast(*align(1) const T, self));
    } else {
        return undefined;
    }
}

const GenCallType = enum {
    BothAsync,
    BothBlocking,
    AsyncCallsBlocking,
    BlockingCallsAsync,
};
