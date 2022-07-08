const std = @import("std");
const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

const ext = struct {
    extern fn fetch(obj: wasm.Obj) wasm.Obj;
    extern fn idbGet(store: wasm.Obj, id: u32) wasm.Obj;
    extern fn idbSet(store: wasm.Obj, id: u32, obj: wasm.Obj) wasm.Obj;
    extern fn timeout(ms: u32) wasm.Obj;
};

fn setData(id: u32, bytes: []const u8) wasm.Obj {
    const obj = wasm.make.slice(.manual, bytes);
    defer obj.delete();

    const promise = ext.idbSet(keys.store_id, id, obj);

    return promise;
}

fn readData(alloc: std.mem.Allocator, id: u32) !?[]const u8 {
    const promise = ext.idbGet(keys.store_id, id);
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

    const promise = setData(0, "blarg");
    promise.Await().delete();
    promise.delete();

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

const Table = wasm.StringTable(.{
    .store_id = "graph-data",
});

var keys: Table.Keys = undefined;

export fn init() void {
    const slot = liu.async_alloc.create(@Frame(awaitTheGuy)) catch unreachable;
    slot.* = async awaitTheGuy();

    keys = Table.init();

    manager_frame = async manager();

    wasm.post(.log, "init done", .{});
}
