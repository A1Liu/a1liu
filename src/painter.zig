const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

// https://github.com/Pagedraw/pagedraw/blob/master/src/frontend/DraggingCanvas.cjsx

// clear canvas
// draw curves with cursor
// create animation/start animation
// undo/redo?
// object tracking with binary search-ish thing
// -> move objects
// -> select objects

const wasm = liu.wasm;
pub const WasmCommand = void;
pub usingnamespace wasm;

const Vec2 = liu.Vec2;
const Vec3 = liu.Vec3;
const Point = struct { pos: Vec2, color: Vec3 };

const ext = struct {
    extern fn renderExt(triangles: wasm.Obj, colors: wasm.Obj) void;
    extern fn readPixel(x: u32, y: u32) wasm.Obj;
    extern fn setColorExt(r: f32, g: f32, b: f32) void;
};

const Render = struct {
    const List = std.ArrayListUnmanaged;
    const Self = @This();

    const TRIANGLE_SIZE: u32 = 12;

    dims: Vec2 = Vec2{ 0, 0 },
    triangles: List(f32) = .{},
    colors: List(f32) = .{},
    temp_begin: ?usize = null,

    pub fn pixelPosition(self: *Self, pos: Vec2) @Vector(2, u32) {
        const dimX = self.dims[0];
        const dimY = self.dims[1];

        const posX = (pos[0] + 1) * dimX / 2;
        const posY = (pos[1] + 1) * dimY / 2;

        const x = @floatToInt(u32, posX);
        const y = @floatToInt(u32, posY);

        return @Vector(2, u32){ x, y };
    }

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

        self.triangles.items.len = temp_begin;
        self.colors.items.len = temp_begin / 2 * 3;
        self.temp_begin = null;

        self.render();
    }

    pub fn useTempData(self: *Self) void {
        std.debug.assert(self.temp_begin != null);

        self.temp_begin = null;
    }

    pub fn startTempStorage(self: *Self) void {
        std.debug.assert(self.temp_begin == null);

        self.temp_begin = self.triangles.items.len;
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

    pub fn pushVert(self: *Self, count: usize) !u32 {
        const len = self.triangles.items.len;
        try self.triangles.appendNTimes(liu.Pages, 0, count * 2);
        try self.colors.appendNTimes(liu.Pages, 0, count * 3);

        return len;
    }

    pub fn drawLine(self: *Self, vertex: u32, from: Point, to: Point) void {
        const pos = self.triangles.items[(vertex)..];
        const color = self.colors.items[(vertex / 2 * 3)..];

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

const Tool = struct {
    const Self = @This();

    const VTable = struct {
        reset: fn (self: *anyopaque) void,
        rightClick: fn (self: *anyopaque, pt: Point) anyerror!void,
        key: fn (self: *anyopaque, code: u32) anyerror!void,
        move: fn (self: *anyopaque, pt: Point) anyerror!void,
        click: fn (self: *anyopaque, pt: Point) anyerror!void,
    };

    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn init(obj: anytype) Self {
        const PtrT = @TypeOf(obj);
        const T = std.meta.Child(PtrT);

        return initWithVtable(T, obj, T);
    }

    pub fn initWithVtable(comptime T: type, obj: *T, comptime VtableType: type) Self {
        const info = std.meta.fieldInfo;

        const Impls = struct {
            fn rightClickMethod(o: *anyopaque, pt: Point) anyerror!void {
                const self = @ptrCast(*T, @alignCast(@alignOf(T), o));

                if (@hasDecl(VtableType, "rightClick")) {
                    return VtableType.rightClick(self, pt);
                }

                return VtableType.reset(self);
            }

            fn keyMethod(o: *anyopaque, code: u32) anyerror!void {
                if (!@hasDecl(VtableType, "key")) return;

                const self = @ptrCast(*T, @alignCast(@alignOf(T), o));
                return VtableType.key(self, code);
            }
        };

        const vtable = comptime VTable{
            .reset = @ptrCast(info(VTable, .reset).field_type, VtableType.reset),
            .rightClick = Impls.rightClickMethod,
            .key = Impls.keyMethod,
            .move = @ptrCast(info(VTable, .move).field_type, VtableType.move),
            .click = @ptrCast(info(VTable, .click).field_type, VtableType.click),
        };

        return Self{ .ptr = @ptrCast(*anyopaque, obj), .vtable = &vtable };
    }

    pub fn reset(self: *Self) void {
        return self.vtable.reset(self.ptr);
    }

    pub fn rightClick(self: *Self, pt: Point) !void {
        return self.vtable.rightClick(self.ptr, pt);
    }

    pub fn key(self: *Self, code: u32) !void {
        return self.vtable.key(self.ptr, code);
    }

    pub fn move(self: *Self, pt: Point) !void {
        return self.vtable.move(self.ptr, pt);
    }

    pub fn click(self: *Self, pt: Point) anyerror!void {
        return self.vtable.click(self.ptr, pt);
    }
};

const ToolKind = enum { click, line, triangle, draw };

var tool_click: ClickTool = .{};
var tool_triangle: TriangleTool = .{};
var tool_line: LineTool = .{};
var tool_draw: DrawTool = .{};

var tool: Tool = Tool.init(&tool_triangle);
var tool_kind: ToolKind = .triangle;

var render: Render = .{};
var current_color: Vec3 = Vec3{ 0.5, 0.5, 0.5 };

var obj_click: wasm.Obj = undefined;
var obj_triangle: wasm.Obj = undefined;
var obj_line: wasm.Obj = undefined;
var obj_draw: wasm.Obj = undefined;

const Math = struct {
    const EPSILON: f32 = 0.0000001;

    // Möller–Trumbore algorithm for triangle-ray intersection algorithm
    fn intersect(vert: u32, ray2: Vec2) bool {
        const pos = render.triangles.items[vert..];

        const ray_origin = liu.vec2Append(ray2, 1);
        const ray = Vec3{ 0, 0, -1 };
        const vert0 = liu.vec2Append(pos[0..2].*, 0);
        const vert1 = liu.vec2Append(pos[2..4].*, 0);
        const vert2 = liu.vec2Append(pos[4..6].*, 0);

        return liu.intersect(EPSILON, ray, ray_origin, .{ vert0, vert1, vert2 });
    }
};

const LineTool = struct {
    prev: ?Point = null,

    const Self = @This();

    fn reset(self: *Self) void {
        render.dropTempData();

        self.prev = null;
    }

    fn move(self: *Self, pt: Point) !void {
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

        _ = try render.pushVert(6);
    }
};

const TriangleTool = struct {
    first: ?Point = null,
    second: ?Point = null,

    const Self = @This();

    fn reset(self: *Self) void {
        render.dropTempData();

        self.first = null;
        self.second = null;
    }

    fn move(self: *Self, pt: Point) !void {
        const first = if (self.first) |first| first else return;

        const temp = render.temp();

        const second = if (self.second) |second| second else {
            render.drawLine(temp, first, pt);
            return;
        };

        render.drawLine(temp + Render.TRIANGLE_SIZE, first, pt);
        render.drawLine(temp + 2 * Render.TRIANGLE_SIZE, second, pt);

        return;
    }

    fn click(self: *Self, pt: Point) !void {
        const first = if (self.first) |first| first else {
            render.startTempStorage();

            self.first = pt;
            _ = try render.pushVert(6);

            return;
        };

        const second = if (self.second) |second| second else {
            self.second = pt;

            _ = try render.pushVert(12);
            return;
        };

        self.reset();
        try render.addTriangle(.{ first, second, pt });
    }
};

const DrawTool = struct {
    const Self = @This();

    previous: ?Point = null,

    fn reset(self: *Self) void {
        render.dropTempData();
        self.previous = null;
    }

    fn move(self: *Self, pt: Point) !void {
        const previous = if (self.previous) |prev| prev else return;
        self.previous = pt;

        const vert = try render.pushVert(6);

        render.drawLine(vert, previous, pt);
    }

    fn click(self: *Self, pt: Point) !void {
        if (self.previous == null) {
            render.startTempStorage();

            self.previous = pt;
        } else {
            render.useTempData();

            self.previous = null;
        }
    }
};

const ClickTool = struct {
    const Self = @This();

    dummy: bool = false,

    fn reset(self: *Self) void {
        _ = self;
    }

    fn rightClick(self: *Self, pt: Point) !void {
        _ = self;

        var _temp = liu.Temp.init();
        const temp = _temp.allocator();
        defer _temp.deinit();

        const pixPos = render.pixelPosition(pt.pos);
        const pixObj = ext.readPixel(pixPos[0], pixPos[1]);
        const bytes = try wasm.in.bytes(pixObj, temp);

        current_color[0] = @intToFloat(f32, bytes[0]) / 255;
        current_color[1] = @intToFloat(f32, bytes[1]) / 255;
        current_color[2] = @intToFloat(f32, bytes[2]) / 255;

        ext.setColorExt(current_color[0], current_color[1], current_color[2]);
    }

    fn move(self: *Self, pt: Point) !void {
        _ = self;
        _ = pt;
    }

    fn click(self: *Self, pt: Point) !void {
        _ = self;

        var i: u32 = render.triangles.items.len;
        std.debug.assert(i % 6 == 0);

        while (i > 0) { // iterate in reverse order
            // we assume that the `triangles` slice is in fact a slice of
            // 2d triangles
            i -= 6;

            const vert = i / 2;
            if (Math.intersect(vert, pt.pos)) {
                const color = render.colors.items[(vert * 3)..];
                color[0..3].* = pt.color;
                color[3..6].* = pt.color;
                color[6..9].* = pt.color;

                render.render();
                break;
            }
        }
    }
};

export fn setColor(r: f32, g: f32, b: f32) void {
    current_color = Vec3{ r, g, b };
}

export fn setDims(width: f32, height: f32) void {
    render.dims = Vec2{ width, height };
}

export fn toggleTool() wasm.Obj {
    tool.reset();

    switch (tool_kind) {
        .click => {
            tool = Tool.init(&tool_triangle);
            tool_kind = .triangle;
            return obj_triangle;
        },
        .triangle => {
            tool = Tool.init(&tool_line);
            tool_kind = .line;
            return obj_line;
        },
        .line => {
            tool = Tool.init(&tool_draw);
            tool_kind = .draw;
            return obj_draw;
        },
        .draw => {
            tool = Tool.init(&tool_click);
            tool_kind = .click;
            return obj_click;
        },
    }
}

export fn onRightClick(posX: f32, posY: f32) void {
    const pt = render.getPoint(posX, posY);

    tool.rightClick(pt) catch @panic("onRightClick failed");
}

export fn onKey(code: u32) void {
    tool.key(code) catch @panic("onKey failed");
}

export fn onMove(posX: f32, posY: f32) void {
    const pt = render.getPoint(posX, posY);

    tool.move(pt) catch @panic("onMove failed");
}

export fn onClick(posX: f32, posY: f32) void {
    const pt = render.getPoint(posX, posY);
    tool.click(pt) catch @panic("onClick failed");
}

export fn init() void {
    wasm.initIfNecessary();

    obj_line = wasm.out.string("line");
    obj_triangle = wasm.out.string("triangle");
    obj_click = wasm.out.string("click");
    obj_draw = wasm.out.string("draw");

    wasm.out.post(.info, "WASM initialized!", .{});
}
