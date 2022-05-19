const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

// clear canvas
// draw freehand/curves with cursor
// create animation/start animation
// undo/redo?
// -> move objects
// -> select objects

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const Vec2 = @Vector(2, f32);
const Vec3 = @Vector(3, f32);
const Point = struct { pos: Vec2, color: Vec3 };

const ext = struct {
    extern fn renderExt(triangles: wasm.Obj, colors: wasm.Obj) void;

    fn onClickExt(posX: f32, posY: f32) callconv(.C) void {
        const pt = render.getPoint(posX, posY);
        onClick(pt) catch @panic("onClick failed");
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
    temp_begin: ?usize = null,

    pub fn getPoint(self: *Self, posX: f32, posY: f32) Point {
        const dimX = self.dims[0];
        const dimY = self.dims[1];

        const pos = Vec2{ posX * 2 / dimX - 1, -(posY * 2 / dimY - 1) };
        const color = current_color;

        return .{ .pos = pos, .color = color };
    }

    pub fn render(self: *Self) void {
        const mark = wasm.watermark();
        defer wasm.setWatermark(mark);

        const obj = wasm.out.slice(self.triangles.items);
        const obj2 = wasm.out.slice(self.colors.items);
        ext.renderExt(obj, obj2);
    }

    pub fn dropTempData(self: *Self) void {
        const temp_begin = if (self.temp_begin) |t| t else return;

        self.triangles.items.len = temp_begin * 2;
        self.colors.items.len = temp_begin * 3;
        self.temp_begin = null;

        self.render();
    }

    pub fn useTempData(self: *Self) void {
        std.debug.assert(self.temp_begin != null);

        self.temp_begin = null;
    }

    pub fn startTempStorage(self: *Self) void {
        std.debug.assert(self.temp_begin == null);

        self.temp_begin = self.triangles.items.len / 2;
    }

    pub fn addTriangle(self: *Self, pts: [3]Point) !void {
        var pos: [6]f32 = undefined;
        pos[0..2].* = pts[0].pos;
        pos[2..4].* = pts[1].pos;
        pos[4..6].* = pts[2].pos;

        var color: [9]f32 = undefined;
        color[0..3].* = pts[0].color;
        color[3..6].* = pts[1].color;
        color[6..9].* = pts[2].color;

        try self.triangles.appendSlice(liu.Pages, &pos);
        try self.colors.appendSlice(liu.Pages, &color);

        self.render();
    }

    pub fn temp(self: *Self) usize {
        if (self.temp_begin) |t| {
            return t;
        }

        unreachable;
    }

    pub fn pushVert(self: *Self, count: usize) !void {
        try self.triangles.appendNTimes(liu.Pages, 0, count * 2);
        try self.colors.appendNTimes(liu.Pages, 0, count * 3);
    }

    pub fn drawLine(self: *Self, vertex: usize, from: Point, to: Point) void {
        const pos = self.triangles.items[(vertex * 2)..];
        const color = self.colors.items[(vertex * 3)..];

        const vector = to.pos - from.pos;
        const rot90: Vec2 = .{ -vector[1], vector[0] };

        const tangent_len = @sqrt(rot90[0] * rot90[0] + rot90[1] * rot90[1]);
        const tangent = rot90 * @splat(2, 2 / tangent_len) / self.dims;

        // first triangle, drawn clockwise
        pos[0..2].* = from.pos + tangent;
        color[0..3].* = from.color;
        pos[2..4].* = to.pos + tangent;
        color[3..6].* = to.color;
        pos[4..6].* = from.pos - tangent;
        color[6..9].* = from.color;

        // second triangle, drawn clockwise
        pos[6..8].* = from.pos - tangent;
        color[9..12].* = from.color;
        pos[8..10].* = to.pos + tangent;
        color[12..15].* = to.color;
        pos[10..12].* = to.pos - tangent;
        color[15..18].* = to.color;

        self.render();
    }
};

// Need to do it this way until pointer aliasing works properly with tagged
// unions at global scope
const EPSILON: f32 = 0.0000001;
const Tool = enum { click, line, triangle };
var tool_line: LineTool = .{};
var tool_triangle: TriangleTool = .{};
var tool_click: ClickTool = .{};
var tool: Tool = .triangle;

var render: Render = .{};
var current_color: Vec3 = Vec3{ 0.5, 0.5, 0.5 };

var obj_line: wasm.Obj = undefined;
var obj_triangle: wasm.Obj = undefined;
var obj_click: wasm.Obj = undefined;

fn intersect(vert: u32, ray2: Vec2) bool {
    const pos = render.triangles.items[(vert * 2)..];

    const makeVec3 = struct {
        fn f(v: Vec2, third: f32) Vec3 {
            var vec: Vec3 = undefined;
            vec[0] = v[0];
            vec[1] = v[1];
            vec[2] = third;

            return vec;
        }
    }.f;

    const cross = struct {
        fn f(a: Vec3, b: Vec3) Vec3 {
            var vec: Vec3 = undefined;
            vec[0] = a[1] * b[2] - a[2] * b[1];
            vec[1] = a[2] * b[0] - a[0] * b[2];
            vec[2] = a[0] * b[1] - a[1] * b[0];

            return vec;
        }
    }.f;

    const dot = struct {
        fn f(a: Vec3, b: Vec3) f32 {
            var vec: Vec3 = a * b;

            return vec[0] + vec[1] + vec[2];
        }
    }.f;

    const ray_origin = makeVec3(ray2, 1);
    const ray = Vec3{ 0, 0, -1 };
    const vert0 = makeVec3(pos[0..2].*, 0);
    const vert1 = makeVec3(pos[2..4].*, 0);
    const vert2 = makeVec3(pos[4..6].*, 0);

    const edge1 = vert1 - vert0;
    const edge2 = vert2 - vert0;

    const h = cross(ray, edge2);
    const a = dot(edge1, h);

    if (a > -EPSILON and a < EPSILON)
        return false; // This ray is parallel to this triangle.

    const f = 1.0 / a;
    const s = ray_origin - vert0;
    const u = f * dot(s, h);
    if (u < 0.0 or u > 1.0)
        return false;
    const q = cross(s, edge1);
    const v = f * dot(ray, q);
    if (v < 0.0 or u + v > 1.0)
        return false;

    // At this stage we can compute t to find out where the intersection point
    // is on the line.
    const t = f * dot(edge2, q);
    if (t > EPSILON) { // ray intersection
        return true;
    } else { // This means that there is a line intersection but not a ray intersection.
        return false;
    }
}

const LineTool = struct {
    prev: ?Point = null,

    const Self = @This();

    fn reset(self: *Self) void {
        self.prev = null;

        render.dropTempData();
    }

    fn move(self: *Self, pt: Point) void {
        const prev = if (self.prev) |prev| prev else return;

        const temp = render.temp();
        render.drawLine(temp, prev, pt);

        return;
    }

    fn click(self: *Self, pt: Point) !void {
        if (self.prev) |_| {
            render.useTempData();
            self.prev = null;
            return;
        }

        render.startTempStorage();
        self.prev = pt;

        try render.pushVert(6);
    }
};

const TriangleTool = struct {
    first: ?Point = null,
    second: ?Point = null,

    const Self = @This();

    fn reset(self: *Self) void {
        self.first = null;
        self.second = null;

        render.dropTempData();
    }

    fn move(self: *Self, pt: Point) void {
        const first = if (self.first) |first| first else return;

        const temp = render.temp();

        const second = if (self.second) |second| second else {
            render.drawLine(temp, first, pt);
            return;
        };

        render.drawLine(temp + 6, first, pt);
        render.drawLine(temp + 12, second, pt);

        return;
    }

    fn click(self: *Self, pt: Point) !void {
        const first = if (self.first) |first| first else {
            render.startTempStorage();

            self.first = pt;
            try render.pushVert(6);

            return;
        };

        const second = if (self.second) |second| second else {
            self.second = pt;

            try render.pushVert(12);
            return;
        };

        self.reset();
        try render.addTriangle(.{ first, second, pt });
    }
};

const ClickTool = struct {
    const Self = @This();

    // selected: bool = false,

    fn reset(self: *Self) void {
        _ = self;
        // self.selected = false;

        // render.dropTempData();
    }

    fn move(self: *Self, pt: Point) void {
        _ = self;
        _ = pt;
    }

    fn click(self: *Self, pt: Point) !void {
        _ = self;
        // if (!self.selected) {
        //     render.startTempStorage();

        //     try render.pushVert(6);

        //     self.selected = true;
        // }

        var i: u32 = render.triangles.items.len;
        std.debug.assert(i % 6 == 0);
        while (i > 0) { // iterate in reverse order
            // we assume that the `triangles` slice is in fact a slice of
            // 2d triangles
            i -= 6;

            const vert = i / 2;
            if (intersect(vert, pt.pos)) {
                const color = render.colors.items[(vert * 3)..];
                color[0..3].* = pt.color;
                color[3..6].* = pt.color;
                color[6..9].* = pt.color;

                render.render();
                break;
            }
        }

        // const temp = render.temp();
        // const orig = Point{ .pos = .{ 0, 0 }, .color = current_color };
        // render.drawLine(temp, orig, pt);
    }
};

export fn setColor(r: f32, g: f32, b: f32) void {
    current_color = Vec3{ r, g, b };
}

export fn setDims(width: f32, height: f32) void {
    render.dims = Vec2{ width, height };
}

export fn currentTool() wasm.Obj {
    switch (tool) {
        .click => return obj_click,
        .triangle => return obj_triangle,
        .line => return obj_line,
    }
}

export fn toggleTool() void {
    switch (tool) {
        .click => {
            const draw = &tool_click;
            draw.reset();

            tool = .triangle;
        },
        .triangle => {
            const draw = &tool_triangle;
            draw.reset();

            tool = .line;
        },
        .line => {
            const draw = &tool_line;
            draw.reset();

            tool = .click;
        },
    }
}

export fn onRightClick() void {
    switch (tool) {
        .click => {
            const draw = &tool_click;
            draw.reset();
        },
        .triangle => {
            const draw = &tool_triangle;
            draw.reset();
        },
        .line => {
            const draw = &tool_line;
            draw.reset();
        },
    }
}

export fn onMove(posX: f32, posY: f32) void {
    const pt = render.getPoint(posX, posY);

    switch (tool) {
        .click => {
            const draw = &tool_click;
            draw.move(pt);
        },
        .triangle => {
            const draw = &tool_triangle;
            draw.move(pt);
        },
        .line => {
            const draw = &tool_line;
            draw.move(pt);
        },
    }
}

pub fn onClick(pt: Point) !void {
    switch (tool) {
        .click => {
            const draw = &tool_click;
            try draw.click(pt);
        },
        .triangle => {
            const draw = &tool_triangle;
            try draw.click(pt);
        },
        .line => {
            const draw = &tool_line;
            try draw.click(pt);
        },
    }
}

pub fn init() !void {
    wasm.initIfNecessary();

    obj_line = wasm.out.string("line");
    obj_triangle = wasm.out.string("triangle");
    obj_click = wasm.out.string("click");

    wasm.out.post(.info, "WASM initialized!", .{});
}
