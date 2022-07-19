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

const Table = wasm.StringTable(.{
    .equation_change = "equationChange",
    .add_tree_item = "addTreeItem",
    .del_tree_item = "delTreeItem",
    .set_root = "setRoot",

    .kind = "kind",
    .id = "id",
    .value = "value",
    .right = "right",
    .left = "left",
    .paren = "paren",

    .plus = "+",
    .minus = "-",
    .multiply = "*",
    .divide = "/",

    .integer = "integer",
});

const EKind = enum(u8) {
    plus = '+',
    minus = '-',
    multiply = '*',
    divide = '/',

    integer = 128,
};

const op_precedence = op_precedence: {
    var precedence: [256]?u8 = [_]?u8{null} ** 256;

    precedence['+'] = 10;
    precedence['-'] = 10;

    precedence['*'] = 20;
    precedence['/'] = 20;

    break :op_precedence precedence;
};

const expr_name_obj = expr_name_obj: {
    var names: [256]?*wasm.Obj = [_]?*wasm.Obj{null} ** 256;

    names[@enumToInt(EKind.plus)] = &keys.plus;
    names[@enumToInt(EKind.minus)] = &keys.minus;

    names[@enumToInt(EKind.multiply)] = &keys.multiply;
    names[@enumToInt(EKind.divide)] = &keys.divide;

    names[@enumToInt(EKind.integer)] = &keys.integer;

    break :expr_name_obj names;
};

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
    paren: void,
});

const ChildrenView = struct {
    left: ?liu.ecs.EntityId,
    right: ?liu.ecs.EntityId,
};

const ParseError = error{
    FailedToParse,
    ExpectedAtom,
    ExpectedClosingParenthesis,
    UnrecognizedAtom,
    DidntFullyConsume,
    OutOfMemory,
};

fn skipWhitespace(index: *usize) void {
    while (index.* < equation.items.len) {
        switch (equation.items[index.*]) {
            ' ', '\t', '\n' => {
                index.* += 1;
            },

            else => break,
        }
    }
}

fn parseEquation(index: *usize) ParseError!liu.ecs.EntityId {
    const id = try parseOp(index, 0);

    skipWhitespace(index);

    if (index.* != equation.items.len) {
        return error.DidntFullyConsume;
    }

    return id;
}

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

            registry.addComponent(id, .kind).?.* = .integer;
            registry.addComponent(id, .value).?.* = @intToFloat(f64, value);

            return id;
        },

        '(' => {
            const op = try parseOp(index, 0);

            skipWhitespace(index);

            const char = pop(index) orelse return error.ExpectedClosingParenthesis;
            if (char != ')') return error.ExpectedClosingParenthesis;

            _ = registry.addComponent(op, .paren);

            return op;
        },

        'a'...'z' => {
            return error.UnrecognizedAtom;
        },

        'A'...'Z' => {
            return error.UnrecognizedAtom;
        },

        else => return error.UnrecognizedAtom,
    }
}

export fn equationChange(equation_obj: wasm.Obj) void {
    equationChangeImpl(equation_obj) catch return;
}

fn addTree(id: liu.ecs.EntityId) void {
    const children = registry.view(ChildrenView).get(id) orelse return;

    const obj = wasm.make.obj(.temp);

    if (children.left) |left| {
        addTree(left);

        const id_obj = wasm.make.integer(.temp, left.index);
        obj.objSet(keys.left, id_obj);
    }

    if (children.right) |right| {
        addTree(right);

        const id_obj = wasm.make.integer(.temp, right.index);
        obj.objSet(keys.right, id_obj);
    }

    const FieldView = struct {
        value: ?f64,
        kind: EKind,
        paren: ?void,
    };

    const fields = registry.view(FieldView).get(id) orelse unreachable;

    const kind_obj = expr_name_obj[@enumToInt(fields.kind)] orelse unreachable;
    obj.objSet(keys.kind, kind_obj.*);

    if (fields.paren != null) {
        obj.objSet(keys.paren, .jstrue);
    }

    if (fields.value) |value| {
        const value_obj = wasm.make.number(.temp, value);
        obj.objSet(keys.value, value_obj);
    }

    const id_obj = wasm.make.integer(.temp, id.index);
    obj.objSet(keys.id, id_obj);

    wasm.postMessage(keys.add_tree_item, obj);
}

fn delTree(id: liu.ecs.EntityId) void {
    const view = registry.view(ChildrenView);

    const children = view.get(id) orelse return;
    if (children.left) |left| delTree(left);
    if (children.right) |right| delTree(right);

    _ = registry.delete(id);

    const id_obj = wasm.make.integer(.temp, id.index);
    wasm.postMessage(keys.del_tree_item, id_obj);
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
    const new_root = parseEquation(&index) catch |e| {
        wasm.post(.log, "failed {s}: {s}", .{ @errorName(e), equation.items });

        return e;
    };

    if (root) |r| delTree(r);

    addTree(new_root);
    {
        const id_obj = wasm.make.integer(.temp, new_root.index);
        wasm.postMessage(keys.set_root, id_obj);
    }

    root = new_root;

    wasm.post(.log, "equation: {s}", .{equation.items});
    wasm.postMessage(keys.equation_change, .jsundefined);
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
