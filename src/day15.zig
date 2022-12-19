const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

// Could replace this with a @Vector to get math ops and simd
const Sensor = struct {
    x: i64,
    y: i64,

    bx: i64,
    by: i64,

    d: i64,

    pub fn format(
        self: Sensor,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        return std.fmt.format(
            writer,
            "Sensor [{},{}] -> Beacon [{},{}], Dist [{}]",
            .{
                self.x,
                self.y,
                self.bx,
                self.by,
                self.d,
            },
        );
    }

    fn inRange(self: Sensor, x: i64, y: i64, ignore: bool) bool {
        if (ignore) {
            if (self.x == x and self.y == y) return false;
            if (self.bx == x and self.by == y) return false;
        }
        return (dist(x, self.x) + dist(y, self.y)) <= self.d;
    }

    fn moveOut(self: Sensor, x: i64, y: i64) i64 {
        var yd = dist(y, self.y);
        var xd: i64 = 0;
        if (x <= self.x) {
            xd = (self.d - yd) + (self.x - x);
        } else {
            xd = (self.d - yd) - (x - self.x);
        }
        return xd + x;
    }
};

fn dist(a: i64, b: i64) i64 {
    @setRuntimeSafety(false);
    return if (a > b) a - b else b - a;
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8, row: i64) !u64 {
    var sensors = std.ArrayList(Sensor).init(allocator);
    defer sensors.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    var max_dist: i64 = 0;
    var min_x: i64 = 1000000000;
    var max_x: i64 = -1000000000;
    while (lines.next()) |line| {
        var tokens = try utils.strSplit(line, ":");
        var offset = std.mem.indexOf(u8, tokens[0], ",").?;
        var x = try std.fmt.parseInt(i64, tokens[0][12..offset], 10);
        var y = try std.fmt.parseInt(i64, tokens[0][offset + 4 ..], 10);
        offset = std.mem.indexOf(u8, tokens[1], ",").?;
        var bx = try std.fmt.parseInt(i64, tokens[1][24..offset], 10);
        var by = try std.fmt.parseInt(i64, tokens[1][offset + 4 ..], 10);
        var d = dist(x, bx) + dist(y, by);
        max_dist = @max(d, max_dist);
        min_x = @min(x, min_x);
        max_x = @max(x, max_x);
        try sensors.append(.{
            .x = x,
            .y = y,
            .bx = bx,
            .by = by,
            .d = d,
        });
    }

    var x: i64 = min_x - max_dist;
    var in_range_count: u32 = 0;
    while (x <= max_x + max_dist) : (x += 1) {
        var found = brk: for (sensors.items) |item| {
            if (item.inRange(x, row, true)) break :brk true;
        } else {
            break :brk false;
        };
        if (found) {
            in_range_count += 1;
        }
    }
    return in_range_count;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8, xrange: i64, yrange: i64) !i64 {
    var sensors = std.ArrayList(Sensor).init(allocator);
    defer sensors.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        var tokens = try utils.strSplit(line, ":");
        var offset = std.mem.indexOf(u8, tokens[0], ",").?;
        var x = try std.fmt.parseInt(i64, tokens[0][12..offset], 10);
        var y = try std.fmt.parseInt(i64, tokens[0][offset + 4 ..], 10);
        offset = std.mem.indexOf(u8, tokens[1], ",").?;
        var bx = try std.fmt.parseInt(i64, tokens[1][24..offset], 10);
        var by = try std.fmt.parseInt(i64, tokens[1][offset + 4 ..], 10);
        var d = dist(x, bx) + dist(y, by);
        try sensors.append(.{
            .x = x,
            .y = y,
            .bx = bx,
            .by = by,
            .d = d,
        });
    }

    const Method = enum {
        brute,
        skip_x,
    };
    const method = Method.skip_x;
    switch (method) {
        .skip_x => {
            var y: i64 = 0;
            while (y <= yrange) : (y += 1) {
                var x: i64 = 0;
                while (x <= xrange) : (x += 1) {
                    for (sensors.items) |item| {
                        if (item.inRange(x, y, false)) {
                            x = item.moveOut(x, y);
                            break;
                        }
                    } else {
                        //std.debug.print("FOUND at {} {}\n", .{x,y});
                        return x * 4000000 + y;
                    }
                }
            }
        },
        .brute => {
            var last = &sensors.items[0];
            var y: i64 = 0;
            while (y <= yrange) : (y += 1) {
                var x: i64 = 0;
                while (x <= xrange) : (x += 1) {
                    if (last.inRange(x, y, false)) continue;

                    for (sensors.items) |*item| {
                        if (item.inRange(x, y, false)) {
                            last = item;
                            break;
                        }
                    } else {
                        //std.debug.print("FOUND at {} {}\n", .{x,y});
                        return x * 4000000 + y;
                    }
                }
                if (@intCast(u64, y) % 1000 == 0) std.debug.print("{}\n", .{y});
            }
        },
    }
    return -1;
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
    try stdout.print("\tpart_1 = {}\n", .{try solve_1(allocator, data, 2000000)});
    try stdout_bw.flush();
    try stdout.print("\tpart_2 = {}\n", .{try solve_2(allocator, data, 4000000, 4000000)});
    try stdout_bw.flush();
}

const test_data =
    \\Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    \\Sensor at x=9, y=16: closest beacon is at x=10, y=16
    \\Sensor at x=13, y=2: closest beacon is at x=15, y=3
    \\Sensor at x=12, y=14: closest beacon is at x=10, y=16
    \\Sensor at x=10, y=20: closest beacon is at x=10, y=16
    \\Sensor at x=14, y=17: closest beacon is at x=10, y=16
    \\Sensor at x=8, y=7: closest beacon is at x=2, y=10
    \\Sensor at x=2, y=0: closest beacon is at x=2, y=10
    \\Sensor at x=0, y=11: closest beacon is at x=2, y=10
    \\Sensor at x=20, y=14: closest beacon is at x=25, y=17
    \\Sensor at x=17, y=20: closest beacon is at x=21, y=22
    \\Sensor at x=16, y=7: closest beacon is at x=15, y=3
    \\Sensor at x=14, y=3: closest beacon is at x=15, y=3
    \\Sensor at x=20, y=1: closest beacon is at x=15, y=3
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data[0..], 10);
    try std.testing.expectEqual(@as(u64, 26), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data[0..], 20, 20);
    try std.testing.expectEqual(@as(i64, 56000011), result);
}
