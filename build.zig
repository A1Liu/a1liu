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
    }

    program.install();
    b.default_step.dependOn(&program.step);

    return program;
}

pub fn build(b: *Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // I cannot get things to work on macbook M1 without doing this. Also,
    // initializing threadlocal doesn't really work on MacOS it seems.
    var target = b.standardTargetOptions(.{});
    target.cpu_arch = Arch.x86_64;

    _ = wasmProgram(b, mode, "kilordle");
    _ = wasmProgram(b, mode, "shapes");

    const playground = b.addExecutable("play", "src/test.zig");
    playground.addPackagePath("liu", "components/zig/lib.zig");
    playground.setBuildMode(mode);

    playground.install();

    // Un-commenting this doesn't output a file, so whatever I guess
    // const all_step = b.step("all", "Build all apps");
    // all_step.dependOn(&kilordle.step);

    const run_cmd = playground.run();
    run_cmd.step.dependOn(&playground.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const native_step = b.step("native", "Build native version");
    // native_step.dependOn(&exe.step);
}
