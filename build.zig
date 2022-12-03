const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const run_all = b.step("run", "Run all days");
    const test_all = b.step("test", "Run all tests");

    const cwd = std.fs.cwd();

    var day: u8 = 0;
    const days = 25;
    while (day <= days) : (day += 1) {
        const day_str = b.fmt("day{}", .{day});
        const day_test_str = b.fmt("test-{s}", .{day_str});
        const src_file = b.fmt("src/{s}.zig", .{day_str});

        const file = cwd.openFile(src_file, .{}) catch break;
        file.close();

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

        const day_test = b.addTest(src_file);
        day_test.setTarget(target);
        day_test.setBuildMode(mode);

        const day_test_step = b.step(day_test_str, day_test_str);
        day_test_step.dependOn(&day_test.step);

        test_all.dependOn(&day_test.step);
    }

    b.default_step = run_all;
}
