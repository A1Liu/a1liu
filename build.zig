const std = @import("std");
const liu = @import("src/liu/lib.zig");
const assets = @import("src/assets.zig");

// var rnd = std.rand.RomuTrio.init(2);
// const a = rnd.random().int(u64);

const bld = std.build;
const Arch = std.Target.Cpu.Arch;
const Builder = bld.Builder;
const Mode = std.builtin.OptimizeMode;

var mode: Mode = undefined;

const ProgData = struct {
    name: []const u8,
    root: []const u8,
};

fn pathTool(b: *Builder, prog: ProgData) *bld.LibExeObjStep {
    const program = b.addExecutable(.{
        .name = prog.name,
        .root_source_file = .{ .path = prog.root },
        .optimize = mode,
    });

    program.addPackagePath("liu", "src/liu/lib.zig");

    program.setOutputDir("config/local/path");

    program.install();
    b.default_step.dependOn(&program.step);

    return program;
}

fn wasmProgram(b: *Builder, prog: ProgData) *bld.LibExeObjStep {
    const program = b.addSharedLibrary(.{
        .name = prog.name,
        .root_source_file = .{ .path = prog.root },
        .version = .{ .major = 0, .minor = 0, .patch = 0 },
        .target = .{ .cpu_arch = .wasm32, .os_tag = .freestanding },
        .optimize = mode,
    });

    program.addPackagePath("liu", "src/liu/lib.zig");
    program.addPackagePath("assets", "src/assets.zig");

    // This is documented literally nowhere; I found it because someone on Discord
    // looked through the source code. The Zig-sponsored way to do this is by
    // using -rdynamic from the CLI, which seems unhelpful to say the least.
    program.rdynamic = true;

    // Output straight to static folder by default to make things easier
    program.setOutputDir("./.zig/zig-out/");

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
    // const target = b.standardTargetOptions(.{});
    mode = b.standardOptimizeOption(.{});

    b.prominent_compile_errors = true;

    const wasmPrograms = [_]ProgData{
        .{
            .name = "kilordle",
            .root = "./src/routes/kilordle/kilordle.zig",
        },
        .{
            .name = "painter",
            .root = "./src/routes/painter/painter.zig",
        },
        .{
            .name = "bench",
            .root = "./src/routes/bench/bench.zig",
        },
        .{
            .name = "algebra",
            .root = "./src/routes/algebra/algebra.zig",
        },
        .{
            .name = "game-2d-simple",
            .root = "./src/routes/game-2d-simple/simple.zig",
        },
    };

    const pathTools = [_]ProgData{.{
        .name = "aliu_path_helper",
        .root = "./src/tools/path_helper.zig",
    }};

    for (wasmPrograms) |p| {
        _ = wasmProgram(b, p);
    }

    for (pathTools) |p| {
        _ = pathTool(b, p);
    }
}
