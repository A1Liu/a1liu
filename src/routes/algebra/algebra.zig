const std = @import("std");
const liu = @import("liu");
const tree = @import("./tree.zig");

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

const Parser = tree.Parser;

const Table = wasm.StringTable(.{
    .equation_change = "equationChange",
    .new_variable = "newVariable",
    .add_tree_item = "addTreeItem",
    .del_tree_item = "delTreeItem",
    .set_root = "setRoot",
    .reset_selected = "resetSelected",

    .kind = "kind",
    .id = "id",
    .implicit = "implicit",
    .name = "name",
    .value = "value",
    .eval_value = "evalValue",
    .right = "right",
    .left = "left",
    .paren = "paren",

    .plus = "+",
    .minus = "-",
    .multiply = "×",
    .divide = "/",

    .integer = "integer",
    .variable = "variable",
});

var root: ?liu.ecs.EntityId = null;
var equation = std.ArrayList(u8).init(liu.Pages);

pub const keys = &keys_;
var keys_: Table.Keys = undefined;

pub const variables = &variables_;
var variables_ = std.ArrayList(struct { name: []const u8, value: f64 }).init(liu.Pages);

pub const registry: *Registry = &registry_data;
var registry_data: Registry = Registry.init(liu.Pages);

pub const EKind = enum(u8) {
    plus = '+',
    minus = '-',
    multiply = '*',
    divide = '/',

    integer = 128,
    variable = 129,
};

pub const Registry = liu.ecs.Registry(struct {
    kind: EKind,
    text: []const u8,
    value: f64,
    left: liu.ecs.EntityId,
    right: liu.ecs.EntityId,
    is_implicit: void,
    paren: void,
});

pub const ChildrenView = struct {
    left: ?liu.ecs.EntityId,
    right: ?liu.ecs.EntityId,
};

const ValueView = struct { value: f64 };

export fn equationChange(equation_obj: wasm.Obj) void {
    equationChangeImpl(equation_obj) catch return;
}

export fn variableUpdate(variable_name: wasm.Obj, new_value: f64) void {
    return variableUpdateImpl(variable_name, new_value) catch unreachable;
}

fn variableUpdateImpl(variable_name: wasm.Obj, new_value: f64) !void {
    const temp_mark = liu.TempMark;
    defer liu.TempMark = temp_mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    const name = try wasm.in.string(variable_name, liu.Temp);

    wasm.post(.log, "variableUpdate of {s}: {}", .{ name, new_value });

    for (variables.items) |*var_info| {
        if (!std.mem.eql(u8, var_info.name, name)) continue;

        var_info.value = new_value;

        wasm.post(.log, "variableUpdate of {s}: done", .{name});
        break;
    }

    try rebuildEquationTree();
}

fn equationChangeImpl(equation_obj: wasm.Obj) !void {
    const temp_mark = liu.TempMark;
    defer liu.TempMark = temp_mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

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

    try rebuildEquationTree();

    wasm.postMessage(keys.equation_change, .jsundefined);
}

fn rebuildEquationTree() !void {
    const temp_mark = liu.TempMark;
    defer liu.TempMark = temp_mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    var parser = Parser{ .data = equation.items };
    const new_root = parser.parseEquation() catch |e| {
        wasm.post(.log, "failed {s} at {}: {s}", .{ @errorName(e), parser.index, equation.items });

        return e;
    };

    wasm.postMessage(keys.reset_selected, .jsundefined);

    if (root) |r| tree.delTree(r);

    _ = tree.evalTree(new_root);

    tree.addTree(new_root);
    {
        const id_obj = wasm.make.integer(.temp, new_root.index);
        wasm.postMessage(keys.set_root, id_obj);
    }

    root = new_root;
}

export fn init() void {
    initImpl() catch unreachable;
}

fn initImpl() !void {
    wasm.initIfNecessary();

    try registry.ensureUnusedCapacity(128);

    keys.* = Table.init();

    wasm.post(.log, "init done", .{});
}
