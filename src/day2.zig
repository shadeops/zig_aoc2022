const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const Play = enum(u8) {
    rock = 1,
    paper = 2,
    scissors = 3,
};

const win = 6;
const draw = 3;

fn getScore(player1: Play, player2: Play) u8 {
    var score = @enumToInt(player2);
    if (player1 == player2) {
        score += draw;
    } else if (player1 == .rock and player2 == .paper) {
        score += win;
    } else if (player1 == .scissors and player2 == .rock) {
        score += win;
    } else if (player1 == .paper and player2 == .scissors) {
        score += win;
    }
    return score;
}

fn getPlay(c: u8) !Play {
    return switch (c) {
        'A', 'X' => .rock,
        'B', 'Y' => .paper,
        'C', 'Z' => .scissors,
        else => error.PlayError,
    };
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var total_score: u64 = 0;
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const player1 = try getPlay(line[0]);
        const player2 = try getPlay(line[2]);
        total_score += getScore(player1, player2);
    }
    return total_score;
}

fn derivePlay(play: Play, c: u8) !Play {
    return switch (play) {
        .rock => switch (c) {
            'X' => .scissors,
            'Y' => .rock,
            'Z' => .paper,
            else => error.DeriveError,
        },
        .paper => switch (c) {
            'X' => .rock,
            'Y' => .paper,
            'Z' => .scissors,
            else => error.DeriveError,
        },
        .scissors => switch (c) {
            'X' => .paper,
            'Y' => .scissors,
            'Z' => .rock,
            else => error.DeriveError,
        },
    };
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var total_score: u64 = 0;
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const player1 = try getPlay(line[0]);
        const player2 = try derivePlay(player1, line[2]);
        total_score += getScore(player1, player2);
    }
    return total_score;
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
    \\A Y
    \\B X
    \\C Z
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 15), result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 12), result);
}
