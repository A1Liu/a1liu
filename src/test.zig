const std = @import("std");
const liu = @import("liu");

const PositionC = struct {
    val: liu.Vec2,
};

const T = struct {};

const Registry = liu.ecs.Registry(struct {
    pos: PositionC,
    asdf: liu.Vec2,
    fdadd: T,
});

var registry: Registry = undefined;

export fn asdf() void {
    registry = Registry.init(16, liu.Pages) catch unreachable;

    var b: T = .{};
    const a: *T = &b;
    a.* = .{};

    const meh = registry.create("") catch unreachable;
    registry.addComponent(meh, .fdadd).?.* = .{};

    var view = registry.view(struct {
        pos: ?*const PositionC,
        asdf: ?liu.Vec2,
        fdadd: ?*T,
    });

    while (view.next()) |elem| {
        _ = elem;
    }
}
