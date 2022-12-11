const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const Board = struct {
    visited: []bool,
    rows: u32,
    cols: u32,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, rows: u32, cols: u32) !Board {
        return .{
            .rows = rows,
            .cols = cols,
            .visited = try allocator.alloc(bool, rows * cols),
            .allocator = allocator,
        };
    }

    fn deinit(self: Board) void {
        self.allocator.free(self.visited);
    }

    fn print(self: Board) void {
        var r: u32 = 0;
        var c: u32 = 0;
        while (r < self.rows) : (r += 1) {
            c = 0;
            while (c < self.cols) : (c += 1) {
                var idx = toIdx(r, c, self.cols);
                if (self.visited[idx]) {
                    std.debug.print("X", .{});
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};

fn toIdx(row: u32, col: u32, cols: u32) u32 {
    return row * cols + col;
}

const Offset = struct {
    row: i32,
    col: i32,

    fn touching(self: Offset) bool {
        return std.math.absCast(self.row) <= 1 and std.math.absCast(self.col) <= 1;
    }

    fn moves(self: Offset) [2]u8 {
        var ret = [_]u8{ 0, 0 };
        if (self.touching()) return ret;
        if (self.row > 0) ret[0] = 'D';
        if (self.row < 0) ret[0] = 'U';
        if (self.col > 0) ret[1] = 'R';
        if (self.col < 0) ret[1] = 'L';
        return ret;
    }

    fn print(self: Offset) void {
        std.debug.print("row: {}, col: {}\n", .{ self.row, self.col });
    }
};

const Position = struct {
    row: u32,
    col: u32,
    cols: u32,
    rows: u32,

    fn idx(self: Position) u32 {
        return self.row * self.cols + self.col;
    }

    fn move(self: *Position, dir: u8) u32 {
        switch (dir) {
            'D' => self.row += 1,
            'U' => self.row -= 1,
            'L' => self.col -= 1,
            'R' => self.col += 1,
            else => {},
        }
        std.debug.assert(self.col < self.cols);
        std.debug.assert(self.row < self.rows);
        return self.idx();
    }

    fn diff(self: Position, other: Position) Offset {
        return .{
            .row = @intCast(i32, self.row) - @intCast(i32, other.row),
            .col = @intCast(i32, self.col) - @intCast(i32, other.col),
        };
    }

    fn print(self: Position) void {
        std.debug.print("[{}] row: {}, col: {}\n", .{ self.idx(), self.row, self.col });
    }
};

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var width_min: i32 = 0;
    var width_max: i32 = 0;
    var height_min: i32 = 0;
    var height_max: i32 = 0;
    var height: i32 = 0;
    var width: i32 = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const tokens = try utils.str_split(line, " ");
        var dist: i32 = try std.fmt.parseInt(i32, tokens[1], 10);
        switch (tokens[0][0]) {
            'D' => {
                height -= dist;
                height_min = @min(height_min, height);
            },
            'U' => {
                height += dist;
                height_max = @max(height_max, height);
            },
            'R' => {
                width -= dist;
                width_min = @min(width_min, width);
            },
            'L' => {
                width += dist;
                width_max = @max(width_max, width);
            },
            else => return error.ParseProblem,
        }
    }

    var board_width = @intCast(u32, width_max - width_min);
    var board_height = @intCast(u32, height_max - height_min);
    board_width *= 2;
    board_height *= 2;

    board_width += 1;
    board_height += 1;

    var board = try Board.init(allocator, board_height, board_width);
    defer board.deinit();

    for (board.visited) |*state| {
        state.* = false;
    }

    var head = Position{
        .row = (board_height / 2),
        .col = (board_width / 2),
        .rows = board_height,
        .cols = board_width,
    };
    var tail = head;

    board.visited[tail.idx()] = true;

    var idx: u32 = 0;

    lines.reset();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const tokens = try utils.str_split(line, " ");
        var dist: u32 = try std.fmt.parseUnsigned(u8, tokens[1], 10);
        var i: u8 = 0;

        var dir = tokens[0][0];

        while (i < dist) : (i += 1) {
            _ = head.move(dir);
            var offset = head.diff(tail);
            var moves = offset.moves();
            idx = tail.move(moves[0]);
            idx = tail.move(moves[1]);

            board.visited[idx] = true;
        }
    }

    var sum: u32 = 0;
    for (board.visited) |state| {
        if (state) sum += 1;
    }
    return sum;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var width_min: i32 = 0;
    var width_max: i32 = 0;
    var height_min: i32 = 0;
    var height_max: i32 = 0;
    var height: i32 = 0;
    var width: i32 = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const tokens = try utils.str_split(line, " ");
        var dist: i32 = try std.fmt.parseInt(i32, tokens[1], 10);
        switch (tokens[0][0]) {
            'D' => {
                height -= dist;
                height_min = @min(height_min, height);
            },
            'U' => {
                height += dist;
                height_max = @max(height_max, height);
            },
            'R' => {
                width -= dist;
                width_min = @min(width_min, width);
            },
            'L' => {
                width += dist;
                width_max = @max(width_max, width);
            },
            else => return error.ParseProblem,
        }
    }

    var board_width = @intCast(u32, width_max - width_min);
    var board_height = @intCast(u32, height_max - height_min);
    board_width *= 2;
    board_height *= 2;

    board_width += 1;
    board_height += 1;

    var board = try Board.init(allocator, board_height, board_width);
    defer board.deinit();

    for (board.visited) |*state| {
        state.* = false;
    }

    var rope = [_]Position{Position{
        .row = (board_height / 2),
        .col = (board_width / 2),
        .rows = board_height,
        .cols = board_width,
    }} ** 10;

    board.visited[rope[9].idx()] = true;

    lines.reset();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const tokens = try utils.str_split(line, " ");
        var dist: u32 = try std.fmt.parseUnsigned(u8, tokens[1], 10);
        var i: u8 = 0;

        var dir = tokens[0][0];
        while (i < dist) : (i += 1) {
            _ = rope[0].move(dir);
            for (rope[1..]) |*knot, n| {
                var offset = rope[n].diff(knot.*);
                var moves = offset.moves();
                _ = knot.move(moves[0]);
                _ = knot.move(moves[1]);
            }
            board.visited[rope[9].idx()] = true;
        }
    }

    var sum: u32 = 0;
    for (board.visited) |state| {
        if (state) sum += 1;
    }
    return sum;
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

const test_data_1 =
    \\R 4
    \\U 4
    \\L 3
    \\D 1
    \\R 4
    \\D 1
    \\L 5
    \\R 2
;

const test_data_2 =
    \\R 5
    \\U 8
    \\L 8
    \\D 3
    \\R 17
    \\D 10
    \\L 25
    \\U 20
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data_1[0..]);
    try std.testing.expectEqual(@as(u64, 13), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data_2[0..]);
    try std.testing.expectEqual(@as(u64, 36), result);
}

// Notes
//  * Instead of pre-building the board, we can just use a AutoHashMap({i32,i32}, bool) to keep track
//      of things.
//  * Also, using a 2D array instead of 1D would cut down on having to carry around stupid rows/cols
