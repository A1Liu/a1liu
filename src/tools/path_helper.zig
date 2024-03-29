const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

var base: []const u8 = "/";
var output: std.ArrayList(u8) = undefined;
var paths: std.StringArrayHashMap(void) = undefined;

pub fn addPath(path_: []const u8) !void {
    var path = path_;
    const result = try paths.getOrPut(path);
    if (result.found_existing) return;

    if (std.mem.startsWith(u8, path, "~/")) {
        try output.appendSlice(base);
        path = path[2..];
    }

    try output.appendSlice(path);
    try output.append(':');
}

pub fn main() !void {
    var arena_ = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var arena = arena_.allocator();

    const args = try std.process.argsAlloc(arena);
    base = args[1];

    output = std.ArrayList(u8).init(arena);
    paths = std.StringArrayHashMap(void).init(arena);

    const env_map = try std.process.getEnvMap(arena);
    const stdout = std.io.getStdOut().writer();

    const path = env_map.get("PATH") orelse return error.MissingPathVariable;
    const cfg_dir = env_map.get("CFG_DIR") orelse return error.MissingCfgVariable;

    {
        const local_path = try std.mem.concat(arena, u8, &.{ cfg_dir, "/local/path" });
        try addPath(local_path);
    }

    // linux gopath
    try addPath("/usr/local/go/bin");

    // gopath
    try addPath("~/go");
    try addPath("~/go/bin");

    try addPath("/opt/homebrew/bin");
    try addPath("/opt/homebrew/Cellar/llvm/14.0.6/bin:$PATH");

    try addPath("~/.rbenv/bin");

    // MacPorts
    try addPath("/opt/local/bin");
    try addPath("/opt/local/sbin");

    {
        var it = std.mem.split(u8, path, ":");
        while (it.next()) |p| {
            try addPath(p);
        }
    }

    // {
    //     for (paths.keys()) |p| {
    //         std.debug.print("PATH: {s}\n", .{p});
    //     }
    // }

    try stdout.print("{s}", .{output.items[0..(output.items.len - 1)]});
}
