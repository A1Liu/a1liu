const std = @import("std");
const liu = @import("liu");

// TODO
// 1. parser, simple pretty-print to GUI
// 2. incremental parser
// 3. visualizers/GUIs
//
// - Easy manipulation of expressions
// - pick/copy/edit points
// - size of things
// - evaluator of expressions
// - grapher (chart.js?)
// - simplification actions + printer of steps
// - GUI follows PEMDAS
// - Bug reporting
// - Tutorials (with video?)

const wasm = liu.wasm;
pub usingnamespace wasm;

// const ext = struct {
//     extern fn fetch(obj: wasm.Obj) wasm.Obj;
//     extern fn timeout(ms: u32) wasm.Obj;
// };

const Table = wasm.StringTable(.{
    .equation_change = "equationChange",
});

var keys: Table.Keys = undefined;
var root: ?liu.ecs.EntityId = null;
var equation = std.ArrayList(u8).init(liu.Pages);

pub const registry: *Registry = &registry_data;
var registry_data: Registry = Registry.init(liu.Pages);

pub const Registry = liu.ecs.Registry(struct {
    kind: EKind,
    value: f64,
    left: liu.ecs.EntityId,
    right: liu.ecs.EntityId,
});

const EKind = enum(u8) {
    Add = '+',

    Integer = 128,
};

const ParseError = error{
    FailedToParse,
    ExpectedAtom,
    UnrecognizedAtom,
    DidntFullyConsume,
    OutOfMemory,
};

fn skipWhitespace(index: *usize) void {
    while (index.* < equation.items.len) {
        switch (equation.items[index.*]) {
            ' ', '\t', '\n' => {
                index.* += 1;
                continue;
            },

            else => break,
        }
    }
}

fn parseEquation(index: *usize) ParseError!liu.ecs.EntityId {
    _ = index;
    // _ = matched_id;

    const id = try parseOp(index, 0);

    skipWhitespace(index);

    if (index.* != equation.items.len) {
        return error.DidntFullyConsume;
    }

    return id;
}

const op_precedence = op_precedence: {
    var precedence: [256]?u8 = [_]?u8{null} ** 256;

    precedence['+'] = 10;

    break :op_precedence precedence;
};

fn peek(index: *usize) ?u8 {
    if (index.* < equation.items.len) return equation.items[index.*];

    return null;
}

fn pop(index: *usize) ?u8 {
    if (index.* < equation.items.len) {
        const char = equation.items[index.*];
        index.* += 1;
        return char;
    }

    return null;
}

fn parseOp(index: *usize, min_precedence: u8) ParseError!liu.ecs.EntityId {

    // const view = registry.view(struct {
    //     left: ?liu.ecs.EntityId,
    //     right: ?liu.ecs.EntityId,
    // });

    // var prev_left_id = matched_id;
    // var prev_right_id = matched_id;

    // if (matched_id) |id| {
    //     const values = view.get(id) orelse unreachable;
    //     prev_left_id = values.left orelse id;
    //     prev_right_id = values.right orelse id;
    // }

    skipWhitespace(index);

    var left_id = try parseAtom(index);

    skipWhitespace(index);

    while (peek(index)) |op| {
        const precedence = op_precedence[op] orelse break;
        if (precedence < min_precedence) break;

        index.* += 1;

        const right_id = try parseOp(index, precedence);

        const op_id = try registry.create("");
        registry.addComponent(op_id, .kind).?.* = @intToEnum(EKind, op);
        registry.addComponent(op_id, .left).?.* = left_id;
        registry.addComponent(op_id, .right).?.* = right_id;

        left_id = op_id;

        skipWhitespace(index);
    }

    return left_id;
}

fn parseAtom(index: *usize) ParseError!liu.ecs.EntityId {
    skipWhitespace(index);

    // _ = matched_id;

    const first = pop(index) orelse return error.ExpectedAtom;
    switch (first) {
        '0'...'9' => {
            var value: u32 = first - '0';

            while (peek(index)) |char| : (index.* += 1) {
                switch (char) {
                    '0'...'9' => {},
                    else => break,
                }

                value *= 10;
                value += char - '0';
            }

            const id = try registry.create("");

            registry.addComponent(id, .kind).?.* = .Integer;
            registry.addComponent(id, .value).?.* = @intToFloat(f64, value);

            return id;
        },

        else => return error.UnrecognizedAtom,
    }
}

export fn equationChange(equation_obj: wasm.Obj) void {
    equationChangeImpl(equation_obj) catch return;
}

fn delTree(id: liu.ecs.EntityId) void {
    const view = registry.view(struct {
        left: ?liu.ecs.EntityId,
        right: ?liu.ecs.EntityId,
    });

    const children = view.get(id) orelse return;
    if (children.left) |left| delTree(left);
    if (children.right) |right| delTree(right);

    _ = registry.delete(id);
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

    var index: usize = 0;
    const prev_root = root;

    root = parseEquation(&index) catch |e| {
        wasm.post(.log, "failed {s}: {s}", .{ @errorName(e), equation.items });

        return e;
    };

    if (prev_root) |r| delTree(r);

    wasm.post(.log, "equation: {s}", .{equation.items});
}

export fn init() void {
    initImpl() catch unreachable;
}

fn initImpl() !void {
    wasm.initIfNecessary();

    try registry.ensureUnusedCapacity(128);

    keys = Table.init();

    wasm.post(.log, "init done", .{});
}
