const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const AlphaBits = std.StaticBitSet(64);

const print_dist_map = false;

const Valve = struct {
    valves: std.ArrayList(*const Valve),
    flow_rate: u8 = 0,
    name: []const u8,
    id: u6 = undefined,

    fn search(self: *const Valve, mins: u8, dist: u8) void {
        std.debug.print("{s}->", .{self.name});
        if (self.flow_rate > 0 and !self.active and mins > (1 + dist)) {
            //std.debug.print("\n  {} {} {}\n", .{self.flow_rate, mins, dist});
            var cost: u32 = 1 + dist;
            var total_flow = self.flow_rate * (mins - cost);
            self.total_flow = @max(total_flow, self.total_flow);
            //std.debug.print(" {}\n", .{self.total_flow});
        }

        if (self.visited) return;
        self.visited = true;
        for (self.valves.items) |next| {
            search(next, mins, dist + 1);
        }
    }

    //    fn searcher(
    //        self: *const Valve,
    //        visited: AlphaBits,
    //        pressure: u32,
    //        mins: u8,
    //    ) u32 {

};

fn single_solver(
    current: *const Valve,
    visited: AlphaBits,
    distances: std.AutoHashMap(Route, u8),
    nodes: []*const Valve,
    current_flow: u32,
    time: u32,
) u32 {
    //std.debug.print("{s} {} {}\n", .{current.name, current_flow, time});
    var new_visited = visited;
    new_visited.set(current.id);

    // times up, this shouldn't be triggered but just in case
    if (time < 1) return current_flow;

    var new_time = time;
    var new_flow = current_flow;

    // This only matters at the start
    if (current.flow_rate != 0) {
        new_time -= 1;
        new_flow += current.flow_rate * new_time;
    }

    var max_flow_rate: u32 = new_flow;
    for (nodes) |node| {
        // we are here now, skip
        if (current.id == node.id) continue;
        // already been here, skip
        if (new_visited.isSet(node.id)) continue;
        const distance = distances.get(.{ .from = current.id, .to = node.id }) orelse unreachable;
        // too far away to do anything, skip
        if (distance >= new_time) continue;
        // let's try!
        var found_flow = single_solver(node, new_visited, distances, nodes, new_flow, new_time - distance);
        max_flow_rate = @max(found_flow, max_flow_rate);
    }
    return max_flow_rate;
}

fn dual_solver(
    current_a: ?*const Valve,
    current_b: ?*const Valve,
    visited: AlphaBits,
    distances: std.AutoHashMap(Route, u8),
    nodes: []*const Valve,
    current_flow: u32,
    time_a: i32,
    time_b: i32,
) u32 {
    _ = current_a;
    _ = current_b;
    _ = visited;
    _ = distances;
    _ = nodes;
    _ = current_flow;
    _ = time_a;
    _ = time_b;
    return 0;
}

fn pathDist(from: *const Valve, to: *const Valve, len: u8, current: *const Valve, visited: AlphaBits) u8 {
    if (current == to) return len;

    var new_visited = visited;
    new_visited.set(current.id);
    //std.debug.print("{s}", .{current.name});
    var min_dist: u8 = 255;
    for (current.valves.items) |v| {
        if (v == from) continue;
        if (new_visited.isSet(v.id)) continue;
        var cur_dist = pathDist(from, to, len + 1, v, new_visited);
        min_dist = @min(cur_dist, min_dist);
    }
    return min_dist;
}

const Route = struct {
    from: u6,
    to: u6,
};

fn solve(allocator: std.mem.Allocator, data: []const u8, single_solve: bool) !u64 {
    var valve_map = std.StringHashMap(*Valve).init(allocator);
    defer valve_map.deinit();

    var valve_list = std.ArrayList(*const Valve).init(allocator);
    defer {
        for (valve_list.items) |valve| {
            valve.valves.deinit();
            allocator.destroy(valve);
        }
        valve_list.deinit();
    }

    const token_template0 = "Valve AA has flow rate=";
    const token_template1 = " tunnel leads to valve ";

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const tokens = try utils.strSplit(line, ";");
        const valve_name = line[6..8];
        const rate = try std.fmt.parseUnsigned(u8, tokens[0][token_template0.len..], 10);
        var other = std.mem.tokenize(u8, tokens[1][token_template1.len..], ", ");

        var valve = valve_map.get(valve_name) orelse blk: {
            var new_valve = try allocator.create(Valve);
            new_valve.* = .{
                .valves = std.ArrayList(*const Valve).init(allocator),
                .name = valve_name,
            };
            try valve_map.putNoClobber(valve_name, new_valve);
            break :blk new_valve;
        };

        try valve_list.append(valve);
        valve.id = @intCast(u6, valve_list.items.len - 1);
        valve.flow_rate = rate;

        while (other.next()) |other_name| {
            //std.debug.print("  {s}\n", .{other_name});
            var other_valve = valve_map.get(other_name) orelse blk: {
                var new_valve = try allocator.create(Valve);
                new_valve.* = .{
                    .valves = std.ArrayList(*const Valve).init(allocator),
                    .name = other_name,
                };
                try valve_map.putNoClobber(other_name, new_valve);
                break :blk new_valve;
            };
            try valve.valves.append(other_valve);
        }
    }

    // Data Structures
    // valve_map: valve.name -> valve
    // valve_list: valve.id -> valve

    const start = valve_map.get("AA") orelse unreachable;
    const start_id = start.id;

    var valve_targets = std.ArrayList(*const Valve).init(allocator);
    defer valve_targets.deinit();

    for (valve_list.items) |valve| {
        //std.debug.print("{s}: {}\n", .{ valve.name, valve.flow_rate });
        if (valve.flow_rate > 0 or valve.id == start_id) {
            try valve_targets.append(valve);
        }
    }

    var dist_map = std.AutoHashMap(Route, u8).init(allocator);
    defer dist_map.deinit();
    for (valve_targets.items) |from| {
        for (valve_targets.items) |to| {
            if (to.id == from.id) continue;

            var visited = AlphaBits.initEmpty();
            var d = pathDist(from, to, 0, from, visited);
            //std.debug.print("{s} {s}\n", .{ to.name, from.name });
            try dist_map.put(.{ .from = from.id, .to = to.id }, d);
            try dist_map.put(.{ .from = to.id, .to = from.id }, d);
        }
    }

    if (print_dist_map) {
        var iter = dist_map.iterator();
        while (iter.next()) |entry| {
            std.debug.print("From {s} to {s} = {}\n", .{
                valve_list.items[entry.key_ptr.*.from].name,
                valve_list.items[entry.key_ptr.*.to].name,
                entry.value_ptr.*,
            });
        }
    }

    if (single_solve)
        return single_solver(start, AlphaBits.initEmpty(), dist_map, valve_targets.items, 0, 30);

    return dual_solver(start, start, AlphaBits.initEmpty(), dist_map, valve_targets.items, 0, 26, 26);
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        _ = line;
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
    try stdout.print("\tpart_1 = {}\n", .{try solve(allocator, data, true)});
    try stdout.print("\tpart_2 = {}\n", .{try solve(allocator, data, false)});
    try stdout_bw.flush();
}

const test_data =
    \\Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
    \\Valve BB has flow rate=13; tunnels lead to valves CC, AA
    \\Valve CC has flow rate=2; tunnels lead to valves DD, BB
    \\Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
    \\Valve EE has flow rate=3; tunnels lead to valves FF, DD
    \\Valve FF has flow rate=0; tunnels lead to valves EE, GG
    \\Valve GG has flow rate=0; tunnels lead to valves FF, HH
    \\Valve HH has flow rate=22; tunnel leads to valve GG
    \\Valve II has flow rate=0; tunnels lead to valves AA, JJ
    \\Valve JJ has flow rate=21; tunnel leads to valve II
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], true);
    try std.testing.expectEqual(@as(u64, 1651), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], false);
    try std.testing.expectEqual(@as(u64, 0), result);
}
