const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const exe = b.addExecutable(.{
        .name = "git-coverage",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the command");
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    const coverage = b.option(bool, "coverage", "Generate coverage") orelse false;
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    if (coverage) {
        exe_unit_tests.setExecCmd(&[_]?[]const u8{
            "kcov",
            "--exclude-pattern=/nix/store",
            "kcov-output",
            null,
        });
    }
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    test_step.dependOn(&run_exe_unit_tests.step);
}
