const std = @import("std");
const liu = @import("liu");

const editor = @import("./editor.zig");
pub const ty = @import("./types.zig");

// TODO better level editor tooling
// spawn point/spawn point mode
// editor mode with free camera, rendering spawn points
//  Ability to select objects, move them, etc
//  Ability to snap to grid
// save which level we're on in localstorage so that refresh is more useful
// line tool bbox check on click
// normalize coords
// form generator code
// record behavior and make bug reporting system

// world bounds?

const util = @import("./util.zig");
const rows = util.rows;
const camera = util.camera;
const KeyCode = liu.gamescreen.KeyCode;
const Timer = liu.gamescreen.Timer;
const FrameInput = liu.gamescreen.FrameInput;

pub fn gon_formatFloatValue(value: f64, writer: anytype) !void {
    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_obj = wasm.out.exactExpFloatPrint(value);
    const output = try wasm.in.string(wasm_obj, liu.Temp);

    try writer.writeAll(output);
}

pub fn gon_parseFloat(bytes: []const u8) !f64 {
    return wasm.parseFloat(bytes);
}

// https://youtu.be/SFKR5rZBu-8?t=2202
// https://stackoverflow.com/questions/22511158/how-to-profile-web-workers-in-chrome

const wasm = liu.wasm;
pub usingnamespace wasm;

pub const Vec2 = ty.Vec2;
pub const Vec3 = ty.Vec3;
pub const Vec4 = ty.Vec4;

pub const ext = struct {
    pub extern fn saveLevelToIdb(levelTextId: wasm.Obj) void;

    pub extern fn clearScreen() void;

    pub extern fn fillStyle(r: f32, g: f32, b: f32, a: f32) void;
    pub extern fn strokeStyle(r: f32, g: f32, b: f32, a: f32) void;

    pub extern fn fillRect(x: i32, y: i32, width: i32, height: i32) void;
    pub extern fn strokeRect(x: i32, y: i32, width: i32, height: i32) void;

    pub extern fn setFont(font: wasm.Obj) void;
    pub extern fn fillText(text: wasm.Obj, x: i32, y: i32) void;
};

export fn init() void {
    wasm.initIfNecessary();

    initErr() catch @panic("meh");

    wasm.post(.log, "WASM initialized!", .{});
}

fn initErr() !void {
    large_font = wasm.make.string(.manual, "bold 48px sans-serif");
    med_font = wasm.make.string(.manual, "24px sans-serif");
    small_font = wasm.make.string(.manual, "10px sans-serif");
    level_download = wasm.make.string(.manual, "levelDownload");
    save_level = wasm.make.string(.manual, "saveLevel");

    try tools.appendSlice(Static, &.{
        try editor.Tool.create(Static, editor.LineTool{}),
        try editor.Tool.create(Static, editor.TestTool{}),
        try editor.Tool.create(Static, editor.DrawTool{}),
        try editor.Tool.create(Static, editor.ClickTool{}),
    });
}

var start_timer: Timer = undefined;
var static_storage: liu.Bump = liu.Bump.init(1024, liu.Pages);
const Static: std.mem.Allocator = static_storage.allocator();

var tools: std.ArrayListUnmanaged(editor.Tool) = .{};
var tool_index: u32 = 0;

pub var large_font: wasm.Obj = undefined;
pub var med_font: wasm.Obj = undefined;
pub var small_font: wasm.Obj = undefined;
pub var level_download: wasm.Obj = undefined;
pub var save_level: wasm.Obj = undefined;
pub var is_editor_mode: bool = false;

export fn uploadLevel(data: wasm.Obj) void {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const asset_data = wasm.in.string(data, liu.Temp) catch |e| {
        wasm.delete(data);
        wasm.post(.err, "Error reading string data: {}", .{e});
        return;
    };

    editor.readFromAsset(asset_data) catch |e| {
        wasm.post(.err, "Error reading asset data: {}", .{e});
        return;
    };
}

export fn download() void {
    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const text = editor.serializeLevel() catch return;

    return wasm.post(level_download, "{s}", .{text});
}

export fn setInitialTime(timestamp: f64) void {
    liu.gamescreen.init(timestamp);

    start_timer = Timer.init();
}

export fn run(timestamp: f64) void {
    var input = liu.gamescreen.frameStart(timestamp);
    defer liu.gamescreen.frameCleanup();

    {
        const pos = input.mouse.pos;
        const world_pos = camera.screenToWorldCoordinates(pos);
        input.mouse.pos = world_pos;

        camera.setDims(input.screen_dims[0], input.screen_dims[1]);
    }

    // Wait for a bit, because otherwise the world will start running
    // before its visible
    if (start_timer.elapsed() < 300) return;

    const delta = input.delta;
    if (delta > 66) {
        wasm.post(.log, "skipped frame", .{});
        return;
    }

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    // Input

    {
        var diff = -input.mouse.scroll_tick[1];
        if (input.key(.arrow_up).pressed) diff -= 1;
        if (input.key(.arrow_down).pressed) diff += 1;

        const new_index = newToolIndex(diff);

        var modified = false;

        if (tool_index != new_index) {
            tools.items[tool_index].reset();
            tool_index = new_index;
            modified = true;
        }

        if (input.key(.key_e).pressed) {
            is_editor_mode = !is_editor_mode;
            tools.items[tool_index].reset();
            modified = true;
        }

        if (!modified and is_editor_mode) {
            // Run the tool on the next frame, let's not get ahead of ourselves
            tools.items[tool_index].frame(input);
        }
    }

    if (!is_editor_mode) {
        var view = ty.registry.view(struct {
            move: *ty.MoveC,
            decide: ty.DecisionC,
            force: ty.ForceC,
        });

        while (view.next()) |elem| {
            const move = elem.move;

            if (!elem.decide.player) continue;

            if (input.key(.key_s).pressed) {
                move.velocity[1] -= 8;
            }

            if (input.key(.key_w).pressed) {
                move.velocity[1] += 8;
            }

            if (elem.force.is_airborne) {
                if (input.key(.key_a).pressed) {
                    move.velocity[0] -= 8;
                }

                if (input.key(.key_d).pressed) {
                    move.velocity[0] += 8;
                }
            } else {
                if (input.key(.key_a).down) {
                    move.velocity[0] -= 8;
                    move.velocity[0] = std.math.clamp(move.velocity[0], -8, 0);
                }

                if (input.key(.key_d).down) {
                    move.velocity[0] += 8;
                    move.velocity[0] = std.math.clamp(move.velocity[0], 0, 8);
                }
            }
        }
    }

    // Gameplay

    // Collisions
    if (!is_editor_mode) {
        var view = ty.registry.view(struct {
            pos: *ty.PositionC,
            move: *ty.MoveC,
            force: *ty.ForceC,
            collide: *ty.CollisionC,
        });

        const StableObject = struct {
            pos: ty.PositionC,
            collide: ty.CollisionC,
            force: ?*const ty.ForceC,
        };

        while (view.next()) |elem| {
            const pos = elem.pos;
            const move = elem.move;

            // move the thing
            var new_bbox = pos.bbox;
            new_bbox.pos = pos.bbox.pos + move.velocity * @splat(2, delta / 1000);

            const bbox = pos.bbox;

            elem.force.is_airborne = true;

            var stable = ty.registry.view(StableObject);
            while (stable.next()) |solid| {
                // No force component means it doesn't interact with gravity,
                // so we'll think of it as a stable piece of the environment
                if (solid.force != null) continue;

                const found = solid.pos.bbox;

                const overlap = new_bbox.overlap(found);
                if (!overlap.result) continue;

                const prev_overlap = bbox.overlap(found);

                if (prev_overlap.x) {
                    if (bbox.pos[1] < found.pos[1]) {
                        new_bbox.pos[1] = found.pos[1] - bbox.height;
                    } else {
                        new_bbox.pos[1] = found.pos[1] + found.height;
                        elem.force.is_airborne = false;
                    }

                    move.velocity[1] = 0;
                }

                if (prev_overlap.y) {
                    if (bbox.pos[0] < found.pos[0]) {
                        new_bbox.pos[0] = found.pos[0] - bbox.width;
                    } else {
                        new_bbox.pos[0] = found.pos[0] + found.width;
                    }

                    move.velocity[0] = 0;
                }
            }

            pos.bbox.pos = new_bbox.pos;

            // const cam_pos0 = camera.pos;
            // const cam_dims = Vec2{ camera.width, camera.height };
            // const cam_pos1 = cam_pos0 + cam_dims;

            // const new_x = std.math.clamp(pos.pos[0], cam_pos0[0], cam_pos1[0] - collide.width);
            // if (new_x != pos.pos[0])
            //     move.velocity[0] = 0;
            // pos.pos[0] = new_x;

            // const new_y = std.math.clamp(pos.pos[1], cam_pos0[1], cam_pos1[1] - collide.height);
            // if (new_y != pos.pos[1])
            //     move.velocity[1] = 0;
            // pos.pos[1] = new_y;
        }
    }

    if (!is_editor_mode) {
        var view = ty.registry.view(struct {
            move: *ty.MoveC,
            force: ty.ForceC,
        });

        while (view.next()) |elem| {
            const move = elem.move;
            const force = elem.force;

            // apply gravity
            move.velocity += force.accel * @splat(2, delta / 1000);

            // applies a friction force when mario hits the ground.
            if (!force.is_airborne and move.velocity[0] != 0) {
                // Friction is applied in the opposite direction of velocity
                // You cannot gain speed in the opposite direction from friction
                const friction: f32 = force.friction * delta;
                if (move.velocity[0] > 0) {
                    move.velocity[0] = std.math.clamp(
                        move.velocity[0] - friction,
                        0,
                        std.math.inf(f32),
                    );
                } else {
                    move.velocity[0] = std.math.clamp(
                        move.velocity[0] + friction,
                        -std.math.inf(f32),
                        0,
                    );
                }
            }
        }
    }

    // Camera Lock
    switch (is_editor_mode) {
        false => {
            var view = ty.registry.view(struct {
                pos: ty.PositionC,
                decide: ty.DecisionC,
            });

            while (view.next()) |elem| {
                if (!elem.decide.player) continue;

                util.moveCamera(elem.pos.bbox.pos);
                break;
            }
        },
        true => {
            const speed: f32 = @as(f32, 16) / 1024 * delta;

            if (input.key(.key_w).down) {
                camera.pos[1] += speed;
            }

            if (input.key(.key_s).down) {
                camera.pos[1] -= speed;
            }

            if (input.key(.key_a).down) {
                camera.pos[0] -= speed;
            }

            if (input.key(.key_d).down) {
                camera.pos[0] += speed;
            }
        },
    }

    // Rendering
    {
        ext.clearScreen();

        var view = ty.registry.view(struct {
            pos: *ty.PositionC,
            render: ty.RenderC,
        });

        while (view.next()) |elem| {
            const pos = elem.pos;
            const render = elem.render;
            const show = switch (is_editor_mode) {
                true => render.editor_visible,
                false => render.game_visible,
            };

            if (!show) continue;

            const color = render.color;
            ext.fillStyle(color[0], color[1], color[2], color[3]);
            const bbox = camera.getScreenBoundingBox(pos.bbox);
            const rect = bbox.renderRectVector();

            ext.fillRect(rect[0], rect[1], rect[2], rect[3]);
        }
    }

    // USER INTERFACE
    renderDebugInfo(input);
}

fn newToolIndex(diff: i32) u32 {
    const new_tool_index = @intCast(i32, tool_index) + diff;
    const len = @intCast(i32, tools.items.len);
    const index = @mod(new_tool_index, len);
    const new_index = @intCast(u32, index);

    return new_index;
}

pub fn renderDebugInfo(input: FrameInput) void {
    if (input.frame_id % 256 == 0) {
        wasm.pushMessage(save_level, .jsundefined);
    }

    if (is_editor_mode) {
        ext.strokeStyle(0.1, 0.1, 0.1, 1);

        const bbox = ty.BBox.unitSquareAt(input.mouse.pos);

        const screen_rect = camera.getScreenBoundingBox(bbox).renderRectVector();
        ext.strokeRect(screen_rect[0], screen_rect[1], screen_rect[2], screen_rect[3]);
    }

    ext.fillStyle(0.5, 0.5, 0.5, 1);

    ext.setFont(large_font);

    {
        const fps_text = wasm.out.string("FPS:");
        const fps_val = wasm.out.fixedFloatPrint(1000 / input.delta, 2);
        ext.fillText(fps_text, 5, 160);
        ext.fillText(fps_val, 120, 160);
    }

    {
        const y: u32 = 220;
        const pos0 = wasm.out.fixedFloatPrint(camera.pos[0], 2);
        ext.fillText(pos0, 5, y);

        const pos1 = wasm.out.fixedFloatPrint(camera.pos[1], 2);
        ext.fillText(pos1, 180, y);
    }

    if (is_editor_mode) {
        const tool_name = wasm.out.string(tools.items[tool_index].name);
        ext.fillText(tool_name, 500, 75);
    }

    if (is_editor_mode) {
        ext.setFont(med_font);
        const prev_tool = wasm.out.string(tools.items[newToolIndex(-1)].name);
        const next_tool = wasm.out.string(tools.items[newToolIndex(1)].name);
        ext.fillText(prev_tool, 530, 25);
        ext.fillText(next_tool, 530, 110);
    }

    // if (is_editor_mode) {
    //     const y: u32 = 250;
    //     const range = wasm.out.fmt("range={}", .{liu.TempMark.range});
    //     const index = wasm.out.fmt("index_in_range={}", .{liu.TempMark.index_in_range});

    //     ext.fillText(range, 5, y);
    //     ext.fillText(index, 5, y + 30);
    // }

    ext.setFont(small_font);

    var topY: i32 = 5;

    for (rows) |row| {
        var leftX = row.leftX;

        for (row.keys) |key| {
            const color: f32 = if (input.key(key).down) 0.3 else 0.5;
            ext.fillStyle(color, color, color, 1);

            ext.fillRect(leftX, topY, 30, 30);

            ext.fillStyle(1, 1, 1, 1);
            const s = &[_]u8{key.code()};
            const letter = wasm.out.string(s);
            ext.fillText(letter, leftX + 15, topY + 10);

            leftX += 35;
        }

        topY += 35;
    }
}

export fn saveLevel() void {
    const wasm_mark = wasm.watermark();
    defer wasm.setWatermark(wasm_mark);

    const mark = liu.TempMark;
    defer liu.TempMark = mark;

    const text = editor.serializeLevel() catch return;
    const wasm_text = wasm.out.string(text);
    ext.saveLevelToIdb(wasm_text);
}
