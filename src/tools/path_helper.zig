const std = @import("std");
const builtin = @import("builtin");
const liu = @import("liu");

var output: std.ArrayList(u8) = undefined;
var paths: std.StringArrayHashMap(void) = undefined;

pub fn addPath(path: []const u8) !void {
    const result = try paths.getOrPut(path);
    if (result.found_existing) return;

    try output.appendSlice(path);
    try output.append(':');
}

pub fn main() !void {
    output = std.ArrayList(u8).init(liu.Temp);
    paths = std.StringArrayHashMap(void).init(liu.Pages);

    const env_map = try std.process.getEnvMap(liu.Pages);
    const stdout = std.io.getStdOut().writer();

    const path = env_map.get("PATH") orelse return error.MissingPathVariable;
    const cfg_dir = env_map.get("CFG_DIR") orelse return error.MissingCfgVariable;

    {
        const local_path = try std.mem.concat(liu.Temp, u8, &.{ cfg_dir, "/local/path" });
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
