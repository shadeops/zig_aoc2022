const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !i64 {
    _ = allocator;

    var lines = std.mem.tokenize(u8, data, "\n");

    var clock_cycle: u32 = 0;
    var execute_time: i32 = 0;
    var signal: i32 = 20;
    var reg: i32 = 1;
    var to_set: i32 = 0;
    var sum: i32 = 0;
    var line: []const u8 = undefined;
    while (true) {
        if (execute_time == 0) {
            reg += to_set;
            line = lines.next() orelse break;
            if (line[0] == 'n') {
                execute_time = 1;
                to_set = 0;
            } else {
                to_set = try std.fmt.parseInt(i32, line[5..], 10);
                execute_time = 2;
            }
        }

        clock_cycle += 1;
        signal -= 1;
        if (signal == 0) {
            signal = 40;
            sum += reg * @intCast(i32, clock_cycle);
        }
        execute_time -= 1;
    }
    return sum;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !i64 {
    _ = allocator;

    var lines = std.mem.tokenize(u8, data, "\n");

    var clock_cycle: u32 = 0;
    var execute_time: i32 = 0;
    var reg: i32 = 1;
    var to_set: i32 = 0;
    var line: []const u8 = undefined;
    var row = [_]u8{'.'} ** 40;
    while (true) {
        if (execute_time == 0) {
            reg += to_set;
            line = lines.next() orelse break;

            if (line[0] == 'n') {
                execute_time = 1;
                to_set = 0;
            } else {
                to_set = try std.fmt.parseInt(i32, line[5..], 10);
                execute_time = 2;
            }
        }

        var col = clock_cycle % 40;
        if (col == reg or col == reg - 1 or col == reg + 1) {
            row[col] = '#';
        }
        if ((clock_cycle) % 40 == 39) {
            std.debug.print("{s}\n", .{row});
            row = [_]u8{'.'} ** 40;
        }
        clock_cycle += 1;
        execute_time -= 1;
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
    \\addx 15
    \\addx -11
    \\addx 6
    \\addx -3
    \\addx 5
    \\addx -1
    \\addx -8
    \\addx 13
    \\addx 4
    \\noop
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx -35
    \\addx 1
    \\addx 24
    \\addx -19
    \\addx 1
    \\addx 16
    \\addx -11
    \\noop
    \\noop
    \\addx 21
    \\addx -15
    \\noop
    \\noop
    \\addx -3
    \\addx 9
    \\addx 1
    \\addx -3
    \\addx 8
    \\addx 1
    \\addx 5
    \\noop
    \\noop
    \\noop
    \\noop
    \\noop
    \\addx -36
    \\noop
    \\addx 1
    \\addx 7
    \\noop
    \\noop
    \\noop
    \\addx 2
    \\addx 6
    \\noop
    \\noop
    \\noop
    \\noop
    \\noop
    \\addx 1
    \\noop
    \\noop
    \\addx 7
    \\addx 1
    \\noop
    \\addx -13
    \\addx 13
    \\addx 7
    \\noop
    \\addx 1
    \\addx -33
    \\noop
    \\noop
    \\noop
    \\addx 2
    \\noop
    \\noop
    \\noop
    \\addx 8
    \\noop
    \\addx -1
    \\addx 2
    \\addx 1
    \\noop
    \\addx 17
    \\addx -9
    \\addx 1
    \\addx 1
    \\addx -3
    \\addx 11
    \\noop
    \\noop
    \\addx 1
    \\noop
    \\addx 1
    \\noop
    \\noop
    \\addx -13
    \\addx -19
    \\addx 1
    \\addx 3
    \\addx 26
    \\addx -30
    \\addx 12
    \\addx -1
    \\addx 3
    \\addx 1
    \\noop
    \\noop
    \\noop
    \\addx -9
    \\addx 18
    \\addx 1
    \\addx 2
    \\noop
    \\noop
    \\addx 9
    \\noop
    \\noop
    \\noop
    \\addx -1
    \\addx 2
    \\addx -37
    \\addx 1
    \\addx 3
    \\noop
    \\addx 15
    \\addx -21
    \\addx 22
    \\addx -6
    \\addx 1
    \\noop
    \\addx 2
    \\addx 1
    \\noop
    \\addx -10
    \\noop
    \\noop
    \\addx 20
    \\addx 1
    \\addx 2
    \\addx 2
    \\addx -6
    \\addx -11
    \\noop
    \\noop
    \\noop
;

const part_2 =
    \\##..##..##..##..##..##..##..##..##..##..
    \\###...###...###...###...###...###...###.
    \\####....####....####....####....####....
    \\#####.....#####.....#####.....#####.....
    \\######......######......######......####
    \\#######.......#######.......#######.....
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(i64, 13140), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(i64, 0), result);
}
