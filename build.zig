const std = @import("std");

const bld = std.build;
const Arch = std.Target.Cpu.Arch;
const Builder = bld.Builder;
const Mode = std.builtin.Mode;

fn wasmProgram(b: *Builder, mode: Mode, comptime name: []const u8) *bld.LibExeObjStep {
    const vers = b.version(0, 0, 0);
    const program = b.addSharedLibrary(name, "src/" ++ name ++ ".zig", vers);

    program.addPackagePath("liu", "components/zig/lib.zig");
    program.setBuildMode(mode);

    program.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    if (mode == .Debug) {
        // Output straight to assets folder during dev to make things easier
        program.setOutputDir("./public/assets");
    } else {
        program.strip = true;
    }

    program.install();
    b.default_step.dependOn(&program.step);

    return program;
}

pub fn build(b: *Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    _ = wasmProgram(b, mode, "kilordle");
    _ = wasmProgram(b, mode, "painter");
    _ = wasmProgram(b, mode, "planner");
}
