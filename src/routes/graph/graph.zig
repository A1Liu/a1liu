const std = @import("std");
const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

const ext = struct {
    extern fn fetch(obj: wasm.Obj) wasm.Obj;
    extern fn idbGet(id: u32) wasm.Obj;
    extern fn timeout(ms: u32) wasm.Obj;
};

fn readData(alloc: std.mem.Allocator, id: u32) !?[]const u8 {
    const promise = ext.idbGet(id);
    defer promise.delete();

    const data_obj = promise.Await();
    if (data_obj == .jsundefined) return null;

    defer data_obj.delete();

    const bytes = try wasm.in.bytes(data_obj, alloc);
    return bytes;
}

// permanent async "manager" task
var manager_frame: @Frame(manager) = undefined;
fn manager() void {}

fn awaitTheGuy() void {
    const url = wasm.make.string(.manual, "https://a1liu.com");
    defer url.delete();

    const timeout = ext.timeout(500);
    defer timeout.delete();

    _ = timeout.Await();

    const data_o = readData(liu.Pages, 0) catch unreachable;
    if (data_o) |data| {
        wasm.post(.log, "{s}", .{data});
    } else {
        wasm.post(.log, "hello", .{});
    }

    const res = ext.fetch(url);
    defer res.delete();

    const out = res.Await();
    defer out.delete();

    wasm.post(.log, "Done!", .{});
}

export fn init() void {
    const slot = liu.async_alloc.create(@Frame(awaitTheGuy)) catch unreachable;
    slot.* = async awaitTheGuy();

    manager_frame = async manager();

    wasm.post(.log, "init done", .{});
}
