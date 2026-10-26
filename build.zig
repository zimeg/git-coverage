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
    run_cmd.addPassthruArgs();
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");
    const coverage = b.option(bool, "coverage", "Generate coverage") orelse false;
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
        // kcov needs the DWARF debug info emitted by LLVM.
        .use_llvm = if (coverage) true else null,
    });
    if (coverage) {
        const run = b.addSystemCommand(&.{
            "kcov",
            "--exclude-pattern=/nix/store",
            "kcov-output",
        });
        run.addArtifactArg(exe_unit_tests);
        test_step.dependOn(&run.step);
    } else {
        const run = b.addRunArtifact(exe_unit_tests);
        test_step.dependOn(&run.step);
    }
}
