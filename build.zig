const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const run_all = b.step("run", "Run all days");
    const test_all = b.step("test", "Run all tests");

    var day: u8 = 1;
    const days = 1;
    while (day <= days) : (day += 1) {
        const day_str = b.fmt("day{}", .{day});
        const src_file = b.fmt("src/{s}.zig", .{day_str});

        const day_exe = b.addExecutable(day_str, src_file);
        day_exe.setTarget(target);
        day_exe.setBuildMode(mode);
        day_exe.install();

        const install_day = b.addInstallArtifact(day_exe);

        const day_run_cmd = day_exe.run();
        day_run_cmd.step.dependOn(&install_day.step);

        run_all.dependOn(&day_run_cmd.step);

        const day_run_step = b.step(day_str, day_str);
        day_run_step.dependOn(&day_run_cmd.step);

        const day_tests = b.addTest(src_file);
        day_tests.setTarget(target);
        day_tests.setBuildMode(mode);

        test_all.dependOn(&day_tests.step);
    }
}
