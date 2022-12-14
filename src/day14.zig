const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const State = enum {
    empty,
    sand,
    rock,
};

const Grid = struct {
    const Self = @This();
    state: []State,
    allocator: std.mem.Allocator,
    x_size: u32,
    y_size: u32,

    fn init(allocator: std.mem.Allocator, x_size: u32, y_size: u32) !Self {
        var grid = Grid{
            .allocator = allocator,
            .x_size = x_size,
            .y_size = y_size,
            .state = try allocator.alloc(State, x_size * y_size),
        };
        for (grid.state) |*state| state.* = .empty;
        return grid;
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.state);
    }

    fn drawLine(self: Self, from_x: u32, to_x: u32, from_y: u32, to_y: u32) !void {
        if (from_x == to_x) {
            // vertical line
            var y_min = @min(to_y, from_y);
            var y_max = @max(to_y, from_y);
            var diff = y_max - y_min;
            var i: u32 = 0;
            while (i <= diff) : (i += 1) {
                self.state[self.offset(to_x, y_min + i).?] = .rock;
            }
        } else if (from_y == to_y) {
            // horizontal line
            var x_min = @min(to_x, from_x);
            var x_max = @max(to_x, from_x);
            var diff = x_max - x_min;
            var i: u32 = 0;
            while (i <= diff) : (i += 1) {
                self.state[self.offset(x_min + i, to_y).?] = .rock;
            }
        } else {
            return error.NonStraightLine;
        }
    }

    fn print(self: Self) void {
        for (self.state) |state, i| {
            switch (state) {
                .empty => std.debug.print(".", .{}),
                .rock => std.debug.print("#", .{}),
                .sand => std.debug.print("o", .{}),
            }
            if ((i % self.x_size) + 1 == self.x_size) std.debug.print("\n", .{});
        }
    }

    fn offset(self: Self, x: u32, y: u32) ?u32 {
        var off = self.x_size * y + x;
        if (off >= self.x_size * self.y_size) return null;
        return off;
    }

    fn findRest(self: Self, x_start: u32, y_start: u32) ?bool {
        var x = x_start;
        var y = y_start;

        var idx = self.offset(x, y) orelse unreachable;

        // Can't spawn new sand
        if (self.state[idx] != .empty) return null;

        while (true) {
            // check below
            idx = self.offset(x, y + 1) orelse return null;
            if (self.state[idx] == .empty) {
                y += 1;
                continue;
            }
            // check left below
            idx = self.offset(x - 1, y + 1) orelse return null;
            if (self.state[idx] == .empty) {
                y += 1;
                x -= 1;
                continue;
            }
            // check right below
            idx = self.offset(x + 1, y + 1) orelse return null;
            if (self.state[idx] == .empty) {
                y += 1;
                x += 1;
                continue;
            }
            break;
        }
        self.state[self.offset(x, y).?] = .sand;
        return true;
    }
};

fn solve(allocator: std.mem.Allocator, data: []const u8, floor: bool) !u64 {
    var x_max: u32 = 0;
    var x_min: u32 = 100000;
    var y_max: u32 = 0;
    var y_min: u32 = 100000;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        var tokens = std.mem.tokenize(u8, line, " -> ");
        while (tokens.next()) |token| {
            var coords = try utils.strSplit(token, ",");
            var x = try std.fmt.parseUnsigned(u32, coords[0], 10);
            var y = try std.fmt.parseUnsigned(u32, coords[1], 10);
            x_max = @max(x_max, x);
            x_min = @min(x_min, x);
            y_max = @max(y_max, y);
            y_min = @min(y_min, y);
        }
    }

    //std.debug.print(
    //    "Draw Bounds: x:{} -> {}, y:{} -> {}\n",
    //    .{ x_min, x_max, y_min, y_max },
    //);

    // drop floor
    y_max += 2;

    x_min = 0;
    x_max *= 2;

    lines.reset();

    var grid = try Grid.init(allocator, x_max - x_min + 1, y_max + 1);
    defer grid.deinit();

    while (lines.next()) |line| {
        var tokens = std.mem.tokenize(u8, line, " -> ");
        var first = true;
        var prev_x: u32 = 0;
        var prev_y: u32 = 0;
        while (tokens.next()) |token| {
            var coords = try utils.strSplit(token, ",");
            var x = try std.fmt.parseUnsigned(u32, coords[0], 10);
            var y = try std.fmt.parseUnsigned(u32, coords[1], 10);

            defer {
                prev_x = x;
                prev_y = y;
            }
            if (first) {
                first = false;
                continue;
            }
            try grid.drawLine(prev_x, x, prev_y, y);
        }
    }

    if (floor) try grid.drawLine(0, x_max, y_max, y_max);

    const start_x = 500;
    const start_y = 0;

    var count: u32 = 0;
    while (grid.findRest(start_x, start_y)) |_| {
        count += 1;
    }

    return count;
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    return solve(allocator, data, false);
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    return solve(allocator, data, true);
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
    \\498,4 -> 498,6 -> 496,6
    \\503,4 -> 502,4 -> 502,9 -> 494,9
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 24), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 93), result);
}
