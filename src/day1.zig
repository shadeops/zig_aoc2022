const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var max_calories: u64 = 0;
    var current_calories: u64 = 0;

    var tokens = std.mem.split(u8, data, "\n");
    while (tokens.next()) |token| {
        current_calories += std.fmt.parseUnsigned(u64, token, 10) catch {
            max_calories = @max(current_calories, max_calories);
            current_calories = 0;
            continue;
        };
    }
    max_calories = @max(current_calories, max_calories);
    return max_calories;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var elf_calories = std.ArrayList(u64).init(allocator);
    defer elf_calories.deinit();

    var current_calories: u64 = 0;

    var tokens = std.mem.split(u8, data, "\n");
    while (tokens.next()) |token| {
        current_calories += std.fmt.parseUnsigned(u64, token, 10) catch {
            try elf_calories.append(current_calories);
            current_calories = 0;
            continue;
        };
    }
    try elf_calories.append(current_calories);

    std.sort.sort(u64, elf_calories.items, {}, comptime std.sort.desc(u64));
    return elf_calories.items[0] + elf_calories.items[1] + elf_calories.items[2];
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
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 24000), result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 45000), result);
}
