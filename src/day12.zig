const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const NeighbourIterator = struct {
    index: usize = 0,
    tile: usize,
    grid_x: usize,
    grid_y: usize,

    fn next(self: *NeighbourIterator) ?usize {
        var x: i32 = @intCast(i32, self.tile % self.grid_x);
        var y: i32 = @intCast(i32, @divFloor(self.tile, self.grid_x));

        switch (self.index) {
            0 => y -= 1,
            1 => x += 1,
            2 => y += 1,
            3 => x -= 1,
            else => return null,
        }
        self.index += 1;
        if (x < 0 or x >= self.grid_x or y < 0 or y >= self.grid_y) return self.next();
        return @intCast(usize, @intCast(i32, self.grid_x) * y + x);
    }
};

fn neighbourIterator(tile: usize, rows: usize, cols: usize) NeighbourIterator {
    return NeighbourIterator{
        .tile = tile,
        .grid_x = cols,
        .grid_y = rows,
    };
}

const IndexPriority = struct {
    idx: usize,
    priority: u32,
};

fn lessThan(context: void, a: IndexPriority, b: IndexPriority) std.math.Order {
    _ = context;
    return std.math.order(a.priority, b.priority);
}

fn greaterThan(context: void, a: IndexPriority, b: IndexPriority) std.math.Order {
    return lessThan(context, a, b).invert();
}

fn slopeHeuristic(current: u32, next: u32) ?u32 {
    if (next > current + 1) return null;
    return 1;
}

fn makeDijkstraMap(
    allocator: std.mem.Allocator,
    start: usize,
    end: usize,
    rows: usize,
    cols: usize,
    costs: std.ArrayList(u8),
    comptime costHeuristic: fn (current: u32, next: u32) ?u32,
) !std.ArrayList(usize) {
    var map_length = @intCast(usize, costs.items.len);
    var unchecked = map_length;

    var map = std.ArrayList(usize).init(allocator);
    errdefer map.deinit();
    try map.resize(map_length);

    for (map.items) |*v| v.* = unchecked;
    map.items[start] = 0;

    var current_costs = std.ArrayList(u32).init(allocator);
    defer current_costs.deinit();
    try current_costs.resize(map_length);

    for (current_costs.items) |*v| v.* = 0;

    const Queue = std.PriorityQueue(IndexPriority, void, lessThan);
    var queue = Queue.init(allocator, {});
    defer queue.deinit();
    try queue.ensureTotalCapacity(map_length);

    try queue.add(.{ .idx = start, .priority = 0 });
    current_costs.items[start] = costs.items[start];

    while (queue.removeOrNull()) |current_priority| {
        var current = current_priority.idx;
        if (current == end) break;

        var iter = neighbourIterator(current, rows, cols);
        while (iter.next()) |next| {
            // Heuristic, can't climb slopes greater than 1 in difference
            var new_cost = current_costs.items[current] + (costHeuristic(costs.items[current], costs.items[next]) orelse continue);

            if (map.items[next] == unchecked or new_cost < current_costs.items[next]) {
                current_costs.items[next] = new_cost;
                try queue.add(.{ .idx = next, .priority = new_cost });
                map.items[next] = current;
            }
        }
        //std.debug.print("\n", .{});
        //for (current_costs.items) |item, i| {
        //    std.debug.print("{} ", .{item});
        //    if ( (i%cols)+1 == cols )
        //        std.debug.print("\n", .{});
        //}

    }
    return map;
}

fn makeBFSPath(
    allocator: std.mem.Allocator,
    start: usize,
    end: usize,
    bfs: std.ArrayList(usize),
) !std.ArrayList(u1) {
    var map = std.ArrayList(u1).init(allocator);
    errdefer map.deinit();
    try map.resize(bfs.items.len);
    for (map.items) |*v| v.* = 0;
    var current = end;
    map.items[current] = 1;
    var count: usize = 1;
    while (current != start) {
        current = bfs.items[current];
        if (current >= map.items.len) return error.InvalidMap;
        map.items[current] = 1;
        count += 1;
    }
    return map;
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var tiles = std.ArrayList(u8).init(allocator);
    defer tiles.deinit();

    var start: usize = 0;
    var end: usize = 0;
    var cols: usize = 0;
    var rows: usize = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        cols = 0;
        for (line) |c| {
            var v: u8 = 0;
            switch (c) {
                'S' => {
                    v = 0;
                    try tiles.append(v);
                    start = tiles.items.len - 1;
                },
                'E' => {
                    v = 25;
                    try tiles.append(v);
                    end = tiles.items.len - 1;
                },
                else => {
                    v = c - 'a';
                    try tiles.append(v);
                },
            }
            cols += 1;
        }
        rows += 1;
    }

    var map = try makeDijkstraMap(allocator, start, end, rows, cols, tiles, slopeHeuristic);
    defer map.deinit();

    var path_map = try makeBFSPath(allocator, start, end, map);
    defer path_map.deinit();

    var steps: u32 = 0;
    for (path_map.items) |item| {
        if (item == 1) steps += 1;
    }

    return steps - 1;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    var tiles = std.ArrayList(u8).init(allocator);
    defer tiles.deinit();

    var start: usize = 0;
    var end: usize = 0;
    var cols: usize = 0;
    var rows: usize = 0;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        cols = 0;
        for (line) |c| {
            var v: u8 = 0;
            switch (c) {
                'S' => {
                    v = 0;
                    try tiles.append(v);
                    start = tiles.items.len - 1;
                },
                'E' => {
                    v = 25;
                    try tiles.append(v);
                    end = tiles.items.len - 1;
                },
                else => {
                    v = c - 'a';
                    try tiles.append(v);
                },
            }
            cols += 1;
        }
        rows += 1;
    }

    var min_steps: u32 = 10000000;
    // TODO this is gross and instead of searching from each starting point, we can just
    // reverse the search and start at the end, and find the first 'a'.
    for (tiles.items) |tile, i| {
        if (tile != 0) continue;
        var map = try makeDijkstraMap(allocator, i, end, rows, cols, tiles, slopeHeuristic);
        defer map.deinit();
        var path_map = makeBFSPath(allocator, i, end, map) catch continue;
        defer path_map.deinit();

        //for (path_map.items) |item, j| {
        //    std.debug.print("{} ", .{item});
        //    if ( (j%cols)+1 == cols )
        //        std.debug.print("\n", .{});
        //}

        var steps: u32 = 0;
        for (path_map.items) |item| {
            if (item == 1) steps += 1;
        }
        min_steps = @min(steps, min_steps);
    }

    return min_steps - 1;
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
    \\Sabqponm
    \\abcryxxl
    \\accszExk
    \\acctuvwj
    \\abdefghi
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 31), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 29), result);
}
