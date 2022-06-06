const std = @import("std");

const bld = std.build;
const Arch = std.Target.Cpu.Arch;
const Builder = bld.Builder;
const Mode = std.builtin.Mode;

var mode: Mode = undefined;

// TODO Asset generator file (src/asset_gen.zig), that stores the definitions
// of created assets and the code to re-generate them from valid data,
// where the valid data is easier to reason about than the produced
// asset files. Ideally the valid data is human-readable.

const ProgData = struct {
    name: []const u8,
    output: []const u8,
    root: []const u8,
};

fn wasmProgram(b: *Builder, prog: ProgData) *bld.LibExeObjStep {
    const vers = b.version(0, 0, 0);
    const program = b.addSharedLibrary(prog.name, prog.root, vers);

    program.addPackagePath("liu", "src/liu/lib.zig");
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

pub fn build(b: *Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    mode = b.standardReleaseOptions();

    _ = wasmProgram(b, .{
        .name = "kilordle",
        .root = "./src/routes/kilordle/kilordle.zig",
        .output = "./static/kilordle/",
    });

    _ = wasmProgram(b, .{
        .name = "painter",
        .root = "./src/routes/painter/painter.zig",
        .output = "./static/painter/",
    });

    _ = wasmProgram(b, .{
        .name = "erlang",
        .root = "./src/routes/erlang/erlang.zig",
        .output = "./static/erlang/",
    });
}
