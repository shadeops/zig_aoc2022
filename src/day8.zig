const std = @import("std");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn toIdx(row: u32, col: u32, cols: u32) u32 {
    return row * cols + col;
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var grid = std.ArrayList(u8).init(allocator);
    defer grid.deinit();

    var visible = std.ArrayList(bool).init(allocator);
    defer visible.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    var cols: u8 = 0;
    var rows: u8 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        for (line) |c| {
            try grid.append(c - '0');
        }
        rows += 1;
        cols = @intCast(u8, line.len);
    }
    try visible.appendNTimes(false, grid.items.len);

    var row: u32 = 0;
    var col: u32 = 0;
    var tallest: u32 = 0;

    // Scan left to right
    row = 1;
    while (row < rows - 1) : (row += 1) {
        col = 1;
        tallest = grid.items[toIdx(row, 0, cols)];
        while (col < cols - 1) : (col += 1) {
            var idx = toIdx(row, col, cols);
            if (grid.items[idx] > tallest) {
                tallest = grid.items[idx];
                visible.items[idx] = true;
            }
            if (tallest == 9) break;
        }
    }

    // Scan right to left
    row = 1;
    while (row < rows - 1) : (row += 1) {
        col = cols - 2;
        tallest = grid.items[toIdx(row, cols - 1, cols)];
        while (col > 0) : (col -= 1) {
            var idx = toIdx(row, col, cols);
            if (grid.items[idx] > tallest) {
                tallest = grid.items[idx];
                visible.items[idx] = true;
            }
            if (tallest == 9) break;
        }
    }

    // Scan top to bottom
    col = 1;
    while (col < cols - 1) : (col += 1) {
        row = 1;
        tallest = grid.items[toIdx(0, col, cols)];
        while (row < rows - 1) : (row += 1) {
            var idx = toIdx(row, col, cols);
            if (grid.items[idx] > tallest) {
                tallest = grid.items[idx];
                visible.items[idx] = true;
            }
            if (tallest == 9) break;
        }
    }

    // Scan bottom to top
    col = 1;
    while (col < cols - 1) : (col += 1) {
        row = rows - 2;
        tallest = grid.items[toIdx(rows - 1, col, cols)];
        while (row > 0) : (row -= 1) {
            var idx = toIdx(row, col, cols);
            if (grid.items[idx] > tallest) {
                tallest = grid.items[idx];
                visible.items[idx] = true;
            }
            if (tallest == 9) break;
        }
    }

    var total_visible: u32 = 0;
    total_visible += cols * 2;
    total_visible += (rows - 2) * 2;

    for (visible.items) |vis| {
        if (vis) total_visible += 1;
    }

    return total_visible;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var grid = std.ArrayList(u8).init(allocator);
    defer grid.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    var cols: u8 = 0;
    var rows: u8 = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        for (line) |c| {
            try grid.append(c - '0');
        }
        rows += 1;
        cols = @intCast(u8, line.len);
    }

    var row: u32 = 0;
    var col: u32 = 0;
    var height: u32 = 0;

    row = 0;
    var high_score: u32 = 0;
    while (row < rows) : (row += 1) {
        col = 0;
        while (col < cols) : (col += 1) {
            var idx = toIdx(row, col, cols);

            height = grid.items[idx];
            var col_i = col;
            var row_i = row;

            var left: u32 = 0;
            var right: u32 = 0;
            var up: u32 = 0;
            var down: u32 = 0;
            // look left
            col_i = col;
            row_i = row;
            while (col_i > 0) {
                col_i -= 1;
                left += 1;
                if (height <= grid.items[toIdx(row_i, col_i, cols)]) break;
            }
            // look right
            col_i = col;
            row_i = row;
            while (col_i < cols - 1) {
                col_i += 1;
                right += 1;
                if (height <= grid.items[toIdx(row_i, col_i, cols)]) break;
            }
            // look up
            col_i = col;
            row_i = row;
            while (row_i > 0) {
                row_i -= 1;
                up += 1;
                if (height <= grid.items[toIdx(row_i, col_i, cols)]) break;
            }
            // look down
            col_i = col;
            row_i = row;
            while (row_i < rows - 1) {
                row_i += 1;
                down += 1;
                if (height <= grid.items[toIdx(row_i, col_i, cols)]) break;
            }
            high_score = @max(high_score, up * down * left * right);
        }
    }

    return high_score;
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
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
;

test "part_1" {
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 21), result);
}

test "part_2" {
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 8), result);
}
