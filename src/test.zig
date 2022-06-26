const std = @import("std");
const liu = @import("liu");

const PositionC = struct {
    val: liu.Vec2,
};

const Registry = liu.ecs_2.Registry(struct {
    pos: PositionC,
    asdf: liu.Vec2,
});

var registry: Registry = undefined;

export fn asdf() void {
    registry = Registry.init(16, liu.Pages) catch unreachable;

    var view = registry.view(struct {
        pos: ?*const PositionC,
        asdf: ?liu.Vec2,
    });

    while (view.next()) |elem| {
        _ = elem;
    }
}
