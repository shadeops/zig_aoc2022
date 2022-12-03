const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn charToNum(c: u8) !u8 {
    return switch (c) {
        'a'...'z' => c - 'a',
        'A'...'Z' => c - 'A' + 26,
        else => error.UnknownChar,
    };
}

const AlphaBits = std.StaticBitSet(26 * 2);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var total_priority: u64 = 0;
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const items = line.len / 2;
        var comp_a = AlphaBits.initEmpty();
        var comp_b = AlphaBits.initEmpty();
        for (line[0..items]) |c| {
            comp_a.set(try charToNum(c));
        }
        for (line[items..]) |c| {
            comp_b.set(try charToNum(c));
        }
        comp_a.setIntersection(comp_b);
        var bit = comp_a.findFirstSet() orelse return error.NoBits;
        total_priority += bit + 1;
    }
    return total_priority;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var total_priority: u64 = 0;
    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        var sack_a = AlphaBits.initEmpty();
        var sack_b = AlphaBits.initEmpty();
        var sack_c = AlphaBits.initEmpty();
        for (line[0..]) |c| {
            sack_a.set(try charToNum(c));
        }
        var next_line = lines.next() orelse return error.NoMoreLines;
        for (next_line[0..]) |c| {
            sack_b.set(try charToNum(c));
        }
        next_line = lines.next() orelse return error.NoMoreLines;
        for (next_line[0..]) |c| {
            sack_c.set(try charToNum(c));
        }
        sack_a.setIntersection(sack_b);
        sack_a.setIntersection(sack_c);

        var bit = sack_a.findFirstSet() orelse return error.NoBits;
        total_priority += bit + 1;
    }
    return total_priority;
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
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 157), result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 70), result);
}
