const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var overlaps: u32 = 0;
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const sections = try utils.str_split(line, ",");

        const elf1 = try utils.str_split(sections[0], "-");
        const elf2 = try utils.str_split(sections[1], "-");

        const elf1_start = try std.fmt.parseUnsigned(u32, elf1[0], 10);
        const elf1_end = try std.fmt.parseUnsigned(u32, elf1[1], 10);

        const elf2_start = try std.fmt.parseUnsigned(u32, elf2[0], 10);
        const elf2_end = try std.fmt.parseUnsigned(u32, elf2[1], 10);

        if (elf1_start >= elf2_start and elf1_end <= elf2_end) {
            overlaps += 1;
            continue;
        }
        if (elf2_start >= elf1_start and elf2_end <= elf1_end) {
            overlaps += 1;
            continue;
        }
    }
    return overlaps;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var overlaps: u32 = 0;
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const sections = try utils.str_split(line, ",");

        const elf1 = try utils.str_split(sections[0], "-");
        const elf2 = try utils.str_split(sections[1], "-");

        const elf1_start = try std.fmt.parseUnsigned(u32, elf1[0], 10);
        const elf1_end = try std.fmt.parseUnsigned(u32, elf1[1], 10);

        const elf2_start = try std.fmt.parseUnsigned(u32, elf2[0], 10);
        const elf2_end = try std.fmt.parseUnsigned(u32, elf2[1], 10);

        if (elf2_start <= elf1_end and elf2_end >= elf1_start) {
            overlaps += 1;
            continue;
        }
    }
    return overlaps;
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
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 2), result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 4), result);
}
