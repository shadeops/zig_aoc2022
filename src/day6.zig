const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const AlphaBits = std.StaticBitSet(26);

fn solve(allocator: std.mem.Allocator, data: []const u8, window: u8) !u64 {
    _ = allocator;

    var bits = AlphaBits.initEmpty();
    for (data[0..window]) |c| bits.toggle(c - 'a');
    for (data) |c, i| {
        if (bits.count() == window) return i + window;
        bits.toggle(c - 'a');
        bits.toggle(data[i + window] - 'a');
    }
    return error.NotFound;
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
    try stdout.print("\tpart_1 = {}\n", .{try solve(allocator, data, 4)});
    try stdout.print("\tpart_2 = {}\n", .{try solve(allocator, data, 14)});
    try stdout_bw.flush();
}

const test_data0 =
    \\mjqjpqmgbljsphdztnvjfqwrcgsmlb
;
const test_data1 =
    \\bvwbjplbgvbhsrlpgdmjqwftvncz
;
const test_data2 =
    \\nppdvjthqldpwncqszvftbrmjlhg
;
const test_data3 =
    \\nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg
;
const test_data4 =
    \\zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw
;

test "part_1" {
    var result = try solve(std.testing.allocator, test_data0[0..], 4);
    try std.testing.expectEqual(@as(u64, 7), result);

    result = try solve(std.testing.allocator, test_data1[0..], 4);
    try std.testing.expectEqual(@as(u64, 5), result);

    result = try solve(std.testing.allocator, test_data2[0..], 4);
    try std.testing.expectEqual(@as(u64, 6), result);

    result = try solve(std.testing.allocator, test_data3[0..], 4);
    try std.testing.expectEqual(@as(u64, 10), result);

    result = try solve(std.testing.allocator, test_data4[0..], 4);
    try std.testing.expectEqual(@as(u64, 11), result);
}

test "part_2" {
    var result = try solve(std.testing.allocator, test_data0[0..], 14);
    try std.testing.expectEqual(@as(u64, 19), result);

    result = try solve(std.testing.allocator, test_data1[0..], 14);
    try std.testing.expectEqual(@as(u64, 23), result);

    result = try solve(std.testing.allocator, test_data2[0..], 14);
    try std.testing.expectEqual(@as(u64, 23), result);

    result = try solve(std.testing.allocator, test_data3[0..], 14);
    try std.testing.expectEqual(@as(u64, 29), result);

    result = try solve(std.testing.allocator, test_data4[0..], 14);
    try std.testing.expectEqual(@as(u64, 26), result);
}
