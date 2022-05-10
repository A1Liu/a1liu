const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const ArrayList = std.ArrayList;
const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);

const ext = struct {
    extern fn setTriangles(obj: wasm.Obj) void;
    extern fn setColors(obj: wasm.Obj) void;

    fn onClickExt(posX: f32, posY: f32, width: f32, height: f32) callconv(.C) void {
        const pos = translatePos(posX, posY, .{ width, height });
        onClick(pos) catch @panic("onClick failed");
    }

    fn initExt() callconv(.C) void {
        init() catch @panic("init failed");
    }
};

comptime {
    @export(ext.onClickExt, .{ .name = "onClick", .linkage = .Strong });
    @export(ext.initExt, .{ .name = "init", .linkage = .Strong });
}

const Render = struct {
    const List = std.ArrayListUnmanaged;
    const Self = @This();

    dims: Vec2 = Vec2{ 0, 0 },
    triangles: List(f32) = .{},
    colors: List(f32) = .{},
    temp_begin: ?usize = 0,

    pub fn dropTempData(self: *Self) void {
        self.triangles.items.len = temp_begin * 2;
        self.colors.items.len = temp_begin * 3;
        self.temp_begin = null;
    }

    pub fn startTempStorage(self: *Self) void {
        self.temp_begin = self.triangles.items.len / 2;
    }

    pub fn addTriangle(self: *Self, pt: Point) !void {
        try self.triangles.appendSlice(liu.Pages, &.{ pt.pos[0], pt.pos[1] });
        try self.colors.appendSlice(liu.Pages, &.{ pt.color[0], pt.color[1], pt.color[2] });
    }

    pub fn temp(self: *Self) usize {
        if (self.temp_begin) |t| {
            return t;
        }

        unreachable;
    }

    pub fn push(self: Self, count: usize) !void {
        try self.triangles.appendNTimes(liu.Pages, 0, count * 2);
        try self.colors.appendNTimes(liu.Pages, 0.5, count * 3);
    }

    pub fn drawLine(self: *Self, vertex: usize, from: Point, to: Point) !void {
        const pos = self.triangles.items[(vertex * 2)..];
        const color = self.triangles.items[(vertex * 3)..];
        const vector = to.pos - from.pos;
        const rot90: Vec2 = .{ -vector[1], vector[0] };

        const tangent_len = @sqrt(rot90[0] * rot90[0] + rot90[1] * rot90[1]);
        const tangent = rot90 * @splat(2, 2 / tangent_len) / self.dims;

        // first triangle, drawn clockwise
        pos[0..2].* = from.pos + tangent;
        color[0..3].* = from.color;
        pos[2..4].* = to + tangent;
        color[3..6].* = to.color;
        pos[4..6].* = from - tangent;
        color[6..9].* = from.color;

        // second triangle, drawn clockwise
        pos[6..8].* = from - tangent;
        color[9..12].* = from.color;
        pos[8..10].* = to + tangent;
        color[12..15].* = to.color;
        pos[10..12].* = to - tangent;
        color[15..18].* = to.color;
    }
};

const Tool = enum {
    none,
    line,
    triangle,
};

var render: Render = .{};

// Need to do it this way until pointer aliasing works properly with tagged
// unions at global scope
var tool_line: LineTool = .{};
var tool_triangle: TriangleTool = .{};
var tool: Tool = .triangle;

var colors: ArrayList(f32) = undefined;
var temp_begin: usize = 0;

var current_color: Vec3 = Vec3{ 0.5, 0.7, 0.5 };

var obj_line: wasm.Obj = undefined;
var obj_triangle: wasm.Obj = undefined;
var obj_none: wasm.Obj = undefined;

fn translatePos(posX: f32, posY: f32, dims: Vec2) Vec2 {
    return .{ posX * 2 / dims[0] - 1, -(posY * 2 / dims[1] - 1) };
}

fn drawLineInto(buffer: *[12]f32, from: Vec2, to: Vec2, dims: Vec2) void {
    const vector = to - from;
    const rot90: Vec2 = .{ -vector[1], vector[0] };

    const tangent_len = @sqrt(rot90[0] * rot90[0] + rot90[1] * rot90[1]);
    const tangent = rot90 * @splat(2, 2 / tangent_len) / dims;

    // first triangle, drawn clockwise
    buffer[0..2].* = from + tangent;
    buffer[2..4].* = to + tangent;
    buffer[4..6].* = from - tangent;

    // second triangle, drawn clockwise
    buffer[6..8].* = from - tangent;
    buffer[8..10].* = to + tangent;
    buffer[10..12].* = to - tangent;
}

const Point = struct {
    pos: Vec2,
    color: Vec3,
};

const LineTool = struct {
    prev: ?Vec2 = null,

    const Self = @This();

    fn reset(self: *Self) bool {
        const changed = self.prev != null;
        self.prev = null;
        return changed;
    }

    fn move(self: *Self, pos: Vec2, dims: Vec2) bool {
        const prev = if (self.prev) |prev| prev else return false;
        const data = render.triangles.items[temp_begin..];
        drawLineInto(data[0..12], prev, pos, dims);

        return true;
    }

    fn click(self: *Self, pos: Vec2) !void {
        if (self.prev) |_| {
            temp_begin = render.triangles.items.len;
            _ = self.reset();
            return;
        }

        self.prev = pos;

        try render.triangles.appendSlice(liu.Pages, &.{
            0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
        });

        var i: usize = 0;
        while (i < 6) : (i += 1) {
            try colors.append(current_color[0]);
            try colors.append(current_color[1]);
            try colors.append(current_color[2]);
        }
    }
};

const TriangleTool = struct {
    first: ?Point = null,
    second: ?Point = null,

    const Self = @This();

    fn reset(self: *Self) bool {
        const changed = self.first != null or self.second != null;
        self.first = null;
        self.second = null;
        return changed;
    }

    fn move(self: *Self, pos: Vec2, dims: Vec2) bool {
        const data = render.triangles.items[temp_begin..];

        const first = if (self.first) |first| first else return false;
        const second = if (self.second) |second| second else {
            drawLineInto(data[0..12], first.pos, pos, dims);
            return true;
        };

        drawLineInto(data[12..24], first.pos, pos, dims);
        drawLineInto(data[24..36], second.pos, pos, dims);

        return true;
    }

    fn click(self: *Self, pos: Vec2) !void {
        const first = if (self.first) |first| first else {
            self.first = .{ .pos = pos, .color = current_color };
            try render.triangles.appendSlice(liu.Pages, &.{
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
            });

            var i: usize = 0;
            while (i < 6) : (i += 1) {
                try colors.append(current_color[0]);
                try colors.append(current_color[1]);
                try colors.append(current_color[2]);
            }

            return;
        };

        const second = if (self.second) |second| second else {
            self.second = .{ .pos = pos, .color = current_color };
            try render.triangles.appendSlice(liu.Pages, &.{
                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,

                0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0,
            });

            var i: usize = 0;
            while (i < 12) : (i += 1) {
                try colors.append(current_color[0]);
                try colors.append(current_color[1]);
                try colors.append(current_color[2]);
            }
            return;
        };

        _ = self.reset();

        render.triangles.items.len = temp_begin;
        colors.items.len = temp_begin / 2 * 3;
        try render.triangles.ensureUnusedCapacity(liu.Pages, 6);
        try render.triangles.appendSlice(liu.Pages, &.{
            first.pos[0],  first.pos[1],
            second.pos[0], second.pos[1],
            pos[0],        pos[1],
        });
        try colors.appendSlice(&.{
            first.color[0],   first.color[1],   first.color[2],
            second.color[0],  second.color[1],  second.color[2],
            current_color[0], current_color[1], current_color[2],
        });
        temp_begin = render.triangles.items.len;

        const obj = wasm.out.slice(render.triangles.items);
        ext.setTriangles(obj);
        const obj2 = wasm.out.slice(colors.items);
        ext.setColors(obj2);
    }
};

export fn setColor(r: f32, g: f32, b: f32) void {
    current_color = Vec3{ r, g, b };
}

export fn currentTool() wasm.Obj {
    switch (tool) {
        .none => return obj_none,
        .triangle => return obj_triangle,
        .line => return obj_line,
    }
}

export fn toggleTool() void {
    switch (tool) {
        .none => {
            tool = .triangle;
        },
        .triangle => {
            const draw = &tool_triangle;
            if (draw.reset()) {
                render.triangles.items.len = temp_begin;
                colors.items.len = temp_begin / 2 * 3;
                const obj = wasm.out.slice(render.triangles.items);
                ext.setTriangles(obj);
                const obj2 = wasm.out.slice(colors.items);
                ext.setColors(obj2);
            }

            tool = .line;
        },
        .line => {
            const draw = &tool_line;
            if (draw.reset()) {
                render.triangles.items.len = temp_begin;
                colors.items.len = temp_begin / 2 * 3;
                const obj = wasm.out.slice(render.triangles.items);
                ext.setTriangles(obj);
                const obj2 = wasm.out.slice(colors.items);
                ext.setColors(obj2);
            }

            tool = .none;
        },
    }
}

export fn onRightClick() void {
    switch (tool) {
        .none => return,
        .triangle => {
            const draw = &tool_triangle;
            if (draw.reset()) {
                render.triangles.items.len = temp_begin;
                colors.items.len = temp_begin / 2 * 3;
                const obj = wasm.out.slice(render.triangles.items);
                ext.setTriangles(obj);
                const obj2 = wasm.out.slice(colors.items);
                ext.setColors(obj2);
            }
        },
        .line => {
            const draw = &tool_line;
            if (draw.reset()) {
                render.triangles.items.len = temp_begin;
                colors.items.len = temp_begin / 2 * 3;
                const obj = wasm.out.slice(render.triangles.items);
                ext.setTriangles(obj);
                const obj2 = wasm.out.slice(colors.items);
                ext.setColors(obj2);
            }
        },
    }
}

export fn onMove(posX: f32, posY: f32, width: f32, height: f32) void {
    const dims: Vec2 = .{ width, height };
    const pos = translatePos(posX, posY, dims);

    switch (tool) {
        .none => return,
        .triangle => {
            const draw = &tool_triangle;
            if (draw.move(pos, dims)) {
                const obj = wasm.out.slice(render.triangles.items);
                ext.setTriangles(obj);
                const obj2 = wasm.out.slice(colors.items);
                ext.setColors(obj2);
            }
        },
        .line => {
            const draw = &tool_line;
            if (draw.move(pos, dims)) {
                const obj = wasm.out.slice(render.triangles.items);
                ext.setTriangles(obj);
                const obj2 = wasm.out.slice(colors.items);
                ext.setColors(obj2);
            }
        },
    }
}

pub fn onClick(pos: Vec2) !void {
    switch (tool) {
        .none => return,
        .triangle => {
            const draw = &tool_triangle;
            try draw.click(pos);
        },
        .line => {
            const draw = &tool_line;
            try draw.click(pos);
        },
    }
}

pub fn init() !void {
    wasm.initIfNecessary();
    // render.triangles = ArrayList(f32).init(liu.Pages);
    colors = ArrayList(f32).init(liu.Pages);

    obj_line = wasm.out.string("line");
    obj_triangle = wasm.out.string("triangle");
    obj_none = wasm.out.string("none");

    wasm.out.post(.info, "WASM initialized!", .{});
}
