const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn solve_1(allocator: std.mem.Allocator, data: []const u8) ![]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var line_iter = std.mem.split(u8, data, "\n");
    var instruction_start: usize = 0;
    while (line_iter.next()) |line| {
        try lines.append(line);
        if (line.len == 0 and instruction_start == 0) instruction_start = lines.items.len;
    }

    var bins_count: usize = 0;
    var bin_iter = std.mem.tokenize(u8, lines.items[instruction_start - 2], " ");
    while (bin_iter.next()) |_| {
        bins_count += 1;
    }

    var bins = try allocator.alloc(std.ArrayList(u8), bins_count);
    defer allocator.free(bins);

    for (bins) |*bin| {
        bin.* = std.ArrayList(u8).init(allocator);
    }
    defer {
        for (bins) |*bin| {
            bin.deinit();
        }
    }

    var line_i: usize = instruction_start - 2;
    while (line_i > 0) {
        line_i -= 1;
        var bin_i: usize = 0;
        while (bin_i < bins_count) : (bin_i += 1) {
            var c = lines.items[line_i][1 + (bin_i * 4)];
            if (c == ' ') continue;
            try bins[bin_i].append(c);
        }
    }

    for (lines.items[instruction_start..]) |line| {
        if (line.len == 0) continue;
        var col_iter = std.mem.split(u8, line, " ");
        var c = col_iter.next() orelse return error.MissingColumn;
        c = col_iter.next() orelse return error.MissingColumn;
        var moves = try std.fmt.parseUnsigned(u32, c, 10);

        c = col_iter.next() orelse return error.MissingColumn;
        c = col_iter.next() orelse return error.MissingColumn;
        var from = try std.fmt.parseUnsigned(u32, c, 10) - 1;

        c = col_iter.next() orelse return error.MissingColumn;
        c = col_iter.next() orelse return error.MissingColumn;
        var to = try std.fmt.parseUnsigned(u32, c, 10) - 1;

        var move_i: usize = 0;
        while (move_i < moves) : (move_i += 1) {
            try bins[to].append(bins[from].pop());
        }
    }

    var top_crates = try allocator.alloc(u8, bins_count);
    for (bins) |bin, i| {
        top_crates[i] = bin.items[bin.items.len - 1];
    }

    return top_crates;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) ![]const u8 {
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    var line_iter = std.mem.split(u8, data, "\n");
    var instruction_start: usize = 0;
    while (line_iter.next()) |line| {
        try lines.append(line);
        if (line.len == 0 and instruction_start == 0) instruction_start = lines.items.len;
    }

    var bins_count: usize = 0;
    var bin_iter = std.mem.tokenize(u8, lines.items[instruction_start - 2], " ");
    while (bin_iter.next()) |_| {
        bins_count += 1;
    }

    var bins = try allocator.alloc(std.ArrayList(u8), bins_count);
    defer allocator.free(bins);

    for (bins) |*bin| {
        bin.* = std.ArrayList(u8).init(allocator);
    }
    defer {
        for (bins) |*bin| {
            bin.deinit();
        }
    }

    var line_i: usize = instruction_start - 2;
    while (line_i > 0) {
        line_i -= 1;
        var bin_i: usize = 0;
        while (bin_i < bins_count) : (bin_i += 1) {
            var c = lines.items[line_i][1 + (bin_i * 4)];
            if (c == ' ') continue;
            try bins[bin_i].append(c);
        }
    }

    for (lines.items[instruction_start..]) |line| {
        if (line.len == 0) continue;
        var col_iter = std.mem.tokenize(u8, line, " ");
        var c = col_iter.next() orelse return error.MissingColumn;
        c = col_iter.next() orelse return error.MissingColumn;
        var moves = try std.fmt.parseUnsigned(u32, c, 10);

        c = col_iter.next() orelse return error.MissingColumn;
        c = col_iter.next() orelse return error.MissingColumn;
        var from = try std.fmt.parseUnsigned(u32, c, 10) - 1;

        c = col_iter.next() orelse return error.MissingColumn;
        c = col_iter.next() orelse return error.MissingColumn;
        var to = try std.fmt.parseUnsigned(u32, c, 10) - 1;

        var from_size = bins[from].items.len;
        var move_slice = bins[from].items[from_size - moves ..];
        try bins[to].appendSlice(move_slice);
        bins[from].shrinkRetainingCapacity(bins[from].items.len - moves);
    }

    var top_crates = try allocator.alloc(u8, bins_count);
    for (bins) |bin, i| {
        top_crates[i] = bin.items[bin.items.len - 1];
    }

    return top_crates;
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
    var s1 = try solve_1(allocator, data);
    defer allocator.free(s1);
    try stdout.print("\tpart_1 = {s}\n", .{s1});
    var s2 = try solve_2(allocator, data);
    defer allocator.free(s2);
    try stdout.print("\tpart_2 = {s}\n", .{s2});
    try stdout_bw.flush();
}

const test_data =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3 
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
    \\
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "CMZ", result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "MCD", result);
}
