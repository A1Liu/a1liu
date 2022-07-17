const std = @import("std");
const liu = @import("liu");

const wasm = liu.wasm;
pub usingnamespace wasm;

const ext = struct {
    extern fn fetch(obj: wasm.Obj) wasm.Obj;
    extern fn timeout(ms: u32) wasm.Obj;
};

const Table = wasm.StringTable(.{
    .equation_change = "equationChange",
});

var keys: Table.Keys = undefined;
var equation = std.ArrayList(u8).init(liu.Pages);

export fn equationChange(equation_obj: wasm.Obj) void {
    equationChangeImpl(equation_obj) catch return;
}

fn equationChangeImpl(equation_obj: wasm.Obj) !void {
    const temp_mark = liu.TempMark;
    defer liu.TempMark = temp_mark;

    const watermark = wasm.watermark();
    defer wasm.setWatermark(watermark);

    {
        var new_equation: []const u8 = try wasm.in.string(equation_obj, liu.Temp);
        new_equation = std.mem.trim(u8, new_equation, " \t\n");

        if (std.mem.eql(u8, equation.items, new_equation)) {
            return;
        }

        try equation.ensureTotalCapacity(new_equation.len);
        equation.clearRetainingCapacity();
        equation.appendSliceAssumeCapacity(new_equation);
    }

    wasm.post(.log, "equation: {s}", .{equation.items});
}

export fn init() void {
    wasm.initIfNecessary();

    keys = Table.init();

    wasm.post(.log, "init done", .{});
}
