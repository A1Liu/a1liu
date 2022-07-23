const std = @import("std");
const liu = @import("liu");
const root = @import("root");

const wasm = liu.wasm;

const keys = root.keys;

const EKind = enum(u8) {
    plus = '+',
    minus = '-',
    multiply = '*',
    divide = '/',

    integer = 128,
    variable = 129,
};

const FieldView = struct {
    kind: EKind,
    text: ?*[]const u8,
    left: ?liu.ecs.EntityId,
    right: ?liu.ecs.EntityId,
    value: ?f64,
    is_implicit: ?void,
    paren: ?void,
};

const ChildrenView = struct {
    left: ?liu.ecs.EntityId,
    right: ?liu.ecs.EntityId,
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

pub const registry: *Registry = &registry_data;
var registry_data: Registry = Registry.init(liu.Pages);

const variables = &variables_;
var variables_ = std.ArrayList(struct { name: []const u8, value: f64 }).init(liu.Pages);

const ParseError = error{
    FailedToParse,
    ExpectedAtom,
    ExpectedClosingParenthesis,
    UnrecognizedAtom,
    DidntFullyConsume,
    OutOfMemory,
};

pub const Parser = struct {
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

    pub fn parseEquation(self: *Self) ParseError!liu.ecs.EntityId {
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

pub fn addTree(id: liu.ecs.EntityId) void {
    const fields = registry.view(FieldView).get(id) orelse return;

    const obj = wasm.make.obj(.temp);

    if (fields.left) |left| {
        addTree(left);

        const id_obj = wasm.make.integer(.temp, left.index);
        obj.objSet(keys.left, id_obj);
    }

    if (fields.right) |right| {
        addTree(right);

        const id_obj = wasm.make.integer(.temp, right.index);
        obj.objSet(keys.right, id_obj);
    }

    const kind_info = expr_name_obj[@enumToInt(fields.kind)] orelse unreachable;
    obj.objSet(keys.kind, kind_info.name_obj.*);

    if (fields.paren != null) obj.objSet(keys.paren, .jstrue);
    if (fields.is_implicit != null) obj.objSet(keys.implicit, .jstrue);

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

pub fn delTree(id: liu.ecs.EntityId) void {
    const view = registry.view(ChildrenView);

    const children = view.get(id) orelse return;
    if (children.left) |left| delTree(left);
    if (children.right) |right| delTree(right);

    _ = registry.delete(id);

    const id_obj = wasm.make.integer(.temp, id.index);
    wasm.postMessage(keys.del_tree_item, id_obj);
}

pub fn evalTree(id: liu.ecs.EntityId) f64 {
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

pub fn updateVariable(variable_name: wasm.Obj, new_value: f64) !void {
    const temp_mark = liu.TempMark;
    defer liu.TempMark = temp_mark;

    const name = try wasm.in.string(variable_name, liu.Temp);

    for (variables.items) |*var_info| {
        if (!std.mem.eql(u8, var_info.name, name)) continue;

        var_info.value = new_value;
        break;
    }
}
