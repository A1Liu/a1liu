const std = @import("std");
const liu = @import("src/liu/lib.zig");
const assets = @import("src/assets.zig");

const bld = std.build;
const Arch = std.Target.Cpu.Arch;
const Builder = bld.Builder;
const Mode = std.builtin.Mode;

var mode: Mode = undefined;

const ProgData = struct {
    name: []const u8,
    output: []const u8,
    root: []const u8,
};

fn wasmProgram(b: *Builder, prog: ProgData) *bld.LibExeObjStep {
    const vers = b.version(0, 0, 0);
    const program = b.addSharedLibrary(prog.name, prog.root, vers);

    program.addPackagePath("liu", "src/liu/lib.zig");
    program.addPackagePath("assets", "src/assets.zig");

    program.setBuildMode(mode);

    program.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });

    // Output straight to static folder by default to make things easier
    program.setOutputDir(prog.output);

    if (mode != .Debug) {
        program.strip = true;
    }

    program.install();
    b.default_step.dependOn(&program.step);

    return program;
}

pub fn build(b: *Builder) !void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    mode = b.standardReleaseOptions();

    // const cache_dir = "./.zig/zig-cache";
    // const out_dir = "./.zig/zig-out";
    // const cwd = std.fs.cwd();

    // try cwd.makePath(cache_dir);
    // try cwd.makePath(out_dir ++ "/lib");
    // try cwd.makePath(out_dir ++ "/bin");
    // try cwd.makePath(out_dir ++ "/include");

    // b.install_prefix = try cwd.realpathAlloc(liu.Temp, "./.zig/zig-out");
    // b.install_path = try cwd.realpathAlloc(liu.Temp, "./.zig/zig-out");
    // b.lib_dir = try cwd.realpathAlloc(liu.Temp, out_dir ++ "/lib");
    // b.exe_dir = try cwd.realpathAlloc(liu.Temp, out_dir ++ "/bin");
    // b.h_dir = try cwd.realpathAlloc(liu.Temp, out_dir ++ "/include");
    // b.dest_dir = try cwd.realpathAlloc(liu.Temp, "./.zig");
    // b.cache_root = try cwd.realpathAlloc(liu.Temp, "./.zig/zig-cache");

    // b.override_dest_dir = "./.zig";

    _ = wasmProgram(b, .{
        .name = "kilordle",
        .root = "./src/routes/kilordle/kilordle.zig",
        .output = "./.zig/zig-out/",
    });

    _ = wasmProgram(b, .{
        .name = "painter",
        .root = "./src/routes/painter/painter.zig",
        .output = "./.zig/zig-out/",
    });

    _ = wasmProgram(b, .{
        .name = "erlang",
        .root = "./src/routes/erlang/erlang.zig",
        .output = "./.zig/zig-out/",
    });
}

// For running scripts/etc.
pub fn main() !void {
    try assets.kilordle.generate();
}

// Experimenting with comptime branch quota
// fn erro() !void {}
// test {
//     comptime {
//         var i: u32 = 0;
//         while (i < 333) : (i += 1) {
//             try erro();
//         }
//     }
// }
