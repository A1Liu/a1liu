const std = @import("std");
const Arch = std.Target.Cpu.Arch;
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // I cannot get things to work on macbook M1 without doing this. Also,
    // initializing threadlocal doesn't really work on MacOS it seems.
    var target = b.standardTargetOptions(.{});
    target.cpu_arch = Arch.x86_64;

    const vers = b.version(0, 0, 0);

    const kilordle = b.addSharedLibrary("kilordle", "src/kilordle.zig", vers);
    kilordle.addPackagePath("assets", "components/assets.zig");
    kilordle.addPackagePath("liu", "components/zig/lib.zig");
    kilordle.setBuildMode(mode);
    kilordle.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    if (mode == .Debug) {
        kilordle.setOutputDir("./public/assets");
    }

    kilordle.install();

    b.default_step.dependOn(&kilordle.step);

    const playground = b.addExecutable("play", "src/test.zig");
    playground.addPackagePath("assets", "components/assets.zig");
    playground.addPackagePath("liu", "components/zig/lib.zig");
    playground.setBuildMode(mode);

    // playground.install();

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
