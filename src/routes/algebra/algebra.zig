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

var keys: Table.Keys = undefined;
var root: ?liu.ecs.EntityId = null;
var equation = std.ArrayList(u8).init(liu.Pages);
var variables = std.ArrayList(struct { name: []const u8, value: f64 }).init(liu.Pages);

pub const registry: *Registry = &registry_data;
var registry_data: Registry = Registry.init(liu.Pages);

const EKind = enum(u8) {
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

const ChildrenView = struct {
    left: ?liu.ecs.EntityId,
    right: ?liu.ecs.EntityId,
};

const ValueView = struct { value: f64 };

const ParseError = error{
    FailedToParse,
    ExpectedAtom,
    ExpectedClosingParenthesis,
    UnrecognizedAtom,
    DidntFullyConsume,
    OutOfMemory,
};

const expr_name_obj = expr_name_obj: {
    const EKindInfo = struct {
        name_obj: *const wasm.Obj,
    };

    var names = [_]?EKindInfo{null} ** 256;

    names[@enumToInt(EKind.plus)] = .{
        .name_obj = &keys.plus,
    };
    names[@enumToInt(EKind.minus)] = .{
        .name_obj = &keys.minus,
    };

    names[@enumToInt(EKind.multiply)] = .{
        .name_obj = &keys.multiply,
    };
    names[@enumToInt(EKind.divide)] = .{
        .name_obj = &keys.divide,
    };

    names[@enumToInt(EKind.integer)] = .{
        .name_obj = &keys.integer,
    };
    names[@enumToInt(EKind.variable)] = .{
        .name_obj = &keys.variable,
    };

    break :expr_name_obj names;
};

const Parser = struct {
    data: []const u8,
    index: usize = 0,

    const Self = @This();

    const PrecedenceInfo = struct {
        op: u8,
        precedence: u8,
        is_explicit: bool = true,
        is_left: bool = true,
    };

    const op_info = op_info: {
        const MUL_PRECEDENCE: u8 = 20;

        var info = [_]?PrecedenceInfo{null} ** 256;

        info['+'] = .{ .op = '+', .precedence = 10 };
        info['-'] = .{ .op = '-', .precedence = 10 };

        info['*'] = .{ .op = '*', .precedence = MUL_PRECEDENCE };
        info['/'] = .{ .op = '/', .precedence = MUL_PRECEDENCE };

        // For cases like "4(1 + 2)", and more commonly, 4x + 3, we want
        // to interpret stuff next to each other as a multiply. the `is_explicit`
        // field says whether to eat a character, and the `op` field says which
        // op we *actually* are, because `(` and `x` are not valid ops.
        const implicit_multiply = PrecedenceInfo{
            .op = '*',
            .precedence = MUL_PRECEDENCE,
            .is_explicit = false,
        };

        info['('] = implicit_multiply;

        {
            var i: u8 = 'a';
            while (i <= 'z') : (i += 1) {
                info[i] = implicit_multiply;
                info[i - 'a' + 'A'] = implicit_multiply;
            }
        }

        {
            var i = '0';
            while (i <= '9') : (i += 1) {
                info[i] = implicit_multiply;
            }
        }

        break :op_info info;
    };

    fn peek(self: *const Self) ?u8 {
        if (self.index < self.data.len) return self.data[self.index];

        return null;
    }

    fn pop(self: *Self) ?u8 {
        if (self.index < self.data.len) {
            const char = self.data[self.index];
            self.index += 1;

            return char;
        }

        return null;
    }

    fn skipWhitespace(self: *Self) void {
        for (self.data[self.index..]) |char| {
            switch (char) {
                ' ', '\t', '\n' => {
                    self.index += 1;
                },

                else => break,
            }
        }
    }

    fn parseEquation(self: *Self) ParseError!liu.ecs.EntityId {
        const id = try self.parseOp();

        self.skipWhitespace();

        if (self.index != self.data.len) {
            return error.DidntFullyConsume;
        }

        return id;
    }

    fn parseOp(self: *Self) ParseError!liu.ecs.EntityId {
        return self.parseOpRec(0);
    }

    fn parseOpRec(self: *Self, min_precedence: u8) ParseError!liu.ecs.EntityId {
        self.skipWhitespace();

        var left_id = try self.parseAtom();

        self.skipWhitespace();

        while (self.peek()) |char| {
            const info: PrecedenceInfo = op_info[char] orelse {
                // error condition here I guess
                break;
            };

            if (info.precedence < min_precedence) break;

            // See op_info definition for explanation
            self.index += @boolToInt(info.is_explicit);

            const new_min = if (info.is_left) info.precedence + 1 else info.precedence;
            const right_id = try self.parseOpRec(new_min);

            const op_id = try registry.create("");
            registry.addComponent(op_id, .kind).?.* = @intToEnum(EKind, info.op);

            if (!info.is_explicit) {
                _ = registry.addComponent(op_id, .is_implicit);
            }

            registry.addComponent(op_id, .left).?.* = left_id;
            registry.addComponent(op_id, .right).?.* = right_id;

            left_id = op_id;

            self.skipWhitespace();
        }

        return left_id;
    }

    fn parseAtom(self: *Self) ParseError!liu.ecs.EntityId {
        self.skipWhitespace();

        const begin = self.index;

        const first = self.pop() orelse return error.ExpectedAtom;
        switch (first) {
            '0'...'9' => {
                // TODO: overflow

                var value: u32 = first - '0';

                while (self.peek()) |char| : (self.index += 1) {
                    switch (char) {
                        '0'...'9' => {},
                        else => break,
                    }

                    value *= 10;
                    value += char - '0';
                }

                const id = try registry.create("");

                registry.addComponent(id, .kind).?.* = .integer;
                registry.addComponent(id, .text).?.* = self.data[begin..self.index];
                registry.addComponent(id, .value).?.* = @intToFloat(f64, value);

                return id;
            },

            '(' => {
                const op = try self.parseOp();

                self.skipWhitespace();

                const char = self.pop() orelse return error.ExpectedClosingParenthesis;
                if (char != ')') return error.ExpectedClosingParenthesis;

                _ = registry.addComponent(op, .paren);

                return op;
            },

            'a'...'z' => {
                const name = self.data[begin..self.index];

                const id = try registry.create("");
                errdefer _ = registry.delete(id);

                const value = variable: {
                    for (variables.items) |var_info| {
                        if (std.mem.eql(u8, var_info.name, name)) {
                            break :variable var_info.value;
                        }
                    }

                    const var_info = try variables.addOne();
                    var_info.* = .{ .name = name, .value = 1 };

                    const name_obj = wasm.make.string(.manual, name);
                    defer name_obj.delete();

                    wasm.postMessage(keys.new_variable, name_obj);

                    break :variable 1;
                };

                registry.addComponent(id, .kind).?.* = .variable;
                registry.addComponent(id, .text).?.* = name;
                registry.addComponent(id, .value).?.* = value;

                return id;
            },

            'A'...'Z' => {
                return error.UnrecognizedAtom;
            },

            else => return error.UnrecognizedAtom,
        }
    }
};

export fn equationChange(equation_obj: wasm.Obj) void {
    equationChangeImpl(equation_obj) catch return;
}

export fn variableUpdate(variable_name: wasm.Obj, new_value: f64) void {
    return variableUpdateImpl(variable_name, new_value) catch unreachable;
}

fn evalTree(id: liu.ecs.EntityId) f64 {
    const view = registry.view(struct {
        kind: EKind,
        value: ?f64,
        left: ?liu.ecs.EntityId,
        right: ?liu.ecs.EntityId,
    });

    const node = view.get(id).?;

    const left = node.left orelse return node.value.?;
    const right = node.right orelse return node.value.?;

    const l = evalTree(left);
    const r = evalTree(right);

    const value = switch (node.kind) {
        .plus => l + r,
        .minus => l - r,

        .multiply => l * r,
        .divide => l / r,

        else => return node.value.?,
    };

    registry.addComponent(id, .value).?.* = value;

    return value;
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
        kind: EKind,
        text: ?*[]const u8,
        value: ?f64,
        is_implicit: ?void,
        paren: ?void,
    };

    const fields = registry.view(FieldView).get(id) orelse unreachable;

    const kind_info = expr_name_obj[@enumToInt(fields.kind)] orelse unreachable;
    obj.objSet(keys.kind, kind_info.name_obj.*);

    if (fields.paren != null) {
        obj.objSet(keys.paren, .jstrue);
    }

    if (fields.is_implicit != null) {
        obj.objSet(keys.implicit, .jstrue);
    }

    if (fields.text) |value| {
        const value_obj = wasm.make.string(.temp, value.*);
        obj.objSet(keys.value, value_obj);
    }

    if (fields.value) |value| {
        const value_obj = wasm.make.number(.temp, value);
        obj.objSet(keys.eval_value, value_obj);
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

    if (root) |r| delTree(r);

    _ = evalTree(new_root);

    addTree(new_root);
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

    keys = Table.init();

    wasm.post(.log, "init done", .{});
}
