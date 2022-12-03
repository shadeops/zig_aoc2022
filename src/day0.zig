const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        _ = line;
    }
    return 0;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        _ = line;
    }
    return 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    const cwd = std.fs.cwd();
    const file = try cwd.openFile(data_path, .{});
    defer file.close();

    var data = try file.readToEndAlloc(allocator, try file.getEndPos());
    defer allocator.free(data);

    const stdout_writer = std.io.getStdOut().writer();
    var stdout_bw = std.io.bufferedWriter(stdout_writer);
    const stdout = stdout_bw.writer();

    try stdout.print("{s}:\n", .{unit_name});
    try stdout.print("\tpart_1 = {}\n", .{try solve_1(allocator, data)});
    try stdout.print("\tpart_2 = {}\n", .{try solve_2(allocator, data)});
    try stdout_bw.flush();
}

const test_data =
    \\test data
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 0), result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 0), result);
}
