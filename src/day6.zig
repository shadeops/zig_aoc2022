const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const AlphaBits = std.StaticBitSet(26);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var bits = AlphaBits.initEmpty();
    for (data[4..]) |_, i| {
        for (data[i .. i + 4]) |c| {
            bits.set(c - 'a');
        }
        if (bits.count() == 4) {
            return i + 4;
        }
        bits.mask = 0;
    }
    return error.NotFound;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var bits = AlphaBits.initEmpty();
    for (data[14..]) |_, i| {
        for (data[i .. i + 14]) |c| {
            bits.set(c - 'a');
        }
        if (bits.count() == 14) {
            return i + 14;
        }
        bits.mask = 0;
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
    try stdout.print("\tpart_1 = {}\n", .{try solve_1(allocator, data)});
    try stdout.print("\tpart_2 = {}\n", .{try solve_2(allocator, data)});
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
    var result = try solve_1(std.testing.allocator, test_data0[0..]);
    try std.testing.expectEqual(@as(u64, 7), result);

    result = try solve_1(std.testing.allocator, test_data1[0..]);
    try std.testing.expectEqual(@as(u64, 5), result);

    result = try solve_1(std.testing.allocator, test_data2[0..]);
    try std.testing.expectEqual(@as(u64, 6), result);

    result = try solve_1(std.testing.allocator, test_data3[0..]);
    try std.testing.expectEqual(@as(u64, 10), result);

    result = try solve_1(std.testing.allocator, test_data4[0..]);
    try std.testing.expectEqual(@as(u64, 11), result);
}

test "part_2" {
    var result = try solve_2(std.testing.allocator, test_data0[0..]);
    try std.testing.expectEqual(@as(u64, 19), result);

    result = try solve_2(std.testing.allocator, test_data1[0..]);
    try std.testing.expectEqual(@as(u64, 23), result);

    result = try solve_2(std.testing.allocator, test_data2[0..]);
    try std.testing.expectEqual(@as(u64, 23), result);

    result = try solve_2(std.testing.allocator, test_data3[0..]);
    try std.testing.expectEqual(@as(u64, 29), result);

    result = try solve_2(std.testing.allocator, test_data4[0..]);
    try std.testing.expectEqual(@as(u64, 26), result);
}
