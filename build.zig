const std = @import("std");

const bld = std.build;
const Arch = std.Target.Cpu.Arch;
const Builder = bld.Builder;
const Mode = std.builtin.Mode;

fn wasmProgram(b: *Builder, mode: Mode, comptime name: []const u8, comptime output_dir: ?[]const u8) *bld.LibExeObjStep {
    const vers = b.version(0, 0, 0);
    const program = b.addSharedLibrary(name, "src/" ++ name ++ ".zig", vers);

    program.addPackagePath("liu", "src/liu/lib.zig");
    program.setBuildMode(mode);

    program.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });

    // Output straight to public folder by default to make things easier
    program.setOutputDir(output_dir orelse "./public/apps");

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
    const mode = b.standardReleaseOptions();

    _ = wasmProgram(b, mode, "kilordle", null);
    _ = wasmProgram(b, mode, "painter", null);
    _ = wasmProgram(b, mode, "erlang", null);
}
