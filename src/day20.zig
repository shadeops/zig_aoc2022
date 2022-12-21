const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const Node = struct {
    prev: ?*Node = null,
    next: ?*Node = null,
    v: i64,
};

fn solve(allocator: std.mem.Allocator, data: []const u8, key: i64, mix: u32) !i64 {
    var vals = std.ArrayList(*Node).init(allocator);
    defer {
        for (vals.items) |val| allocator.destroy(val);
        vals.deinit();
    }

    var lines = std.mem.tokenize(u8, data, "\n");
    var starter_node: ?*Node = null;
    while (lines.next()) |line| {
        var new_node = try allocator.create(Node);
        new_node.v = try std.fmt.parseInt(i64, line, 10) * key;
        if (new_node.v == 0) starter_node = new_node;
        try vals.append(new_node);
    }

    for (vals.items[1..]) |val, i| {
        val.prev = vals.items[i];
    }
    vals.items[0].prev = vals.items[vals.items.len - 1];

    for (vals.items[0 .. vals.items.len - 1]) |val, i| {
        val.next = vals.items[i + 1];
    }
    vals.items[vals.items.len - 1].next = vals.items[0];

    var mix_loop: u32 = 0;
    while (mix_loop < mix) : (mix_loop += 1) {
        for (vals.items) |val| {
            if (val.v == 0) continue;

            var i: usize = 0;
            var current_node: ?*Node = val;

            // update links, first val's original neighbours
            val.prev.?.next = val.next;
            val.next.?.prev = val.prev;

            if (val.v < 0) {
                const mixes = @intCast(u64, -val.v) % (vals.items.len - 1) + 1;
                while (i < mixes) : (i += 1) {
                    current_node = current_node.?.prev;
                }
            } else {
                const mixes = @intCast(u64, val.v) % (vals.items.len - 1);
                while (i < mixes) : (i += 1) {
                    current_node = current_node.?.next;
                }
            }

            // update val.
            val.prev = current_node;
            val.next = current_node.?.next;

            // now given the current node, insert val
            current_node.?.next.?.prev = val;
            current_node.?.next = val;
        }
    }

    var c: *Node = starter_node.?;
    var i: usize = 0;
    var coord: i64 = 0;
    while (i <= 3000) : (i += 1) {
        if (i == 1000) coord += c.v;
        if (i == 2000) coord += c.v;
        if (i == 3000) coord += c.v;
        c = c.next.?;
    }

    return coord;
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
    try stdout.print("\tpart_1 = {}\n", .{try solve(allocator, data, 1, 1)});
    try stdout_bw.flush();
    try stdout.print("\tpart_2 = {}\n", .{try solve(allocator, data, 811589153, 10)});
    try stdout_bw.flush();
}

const test_data =
    \\1
    \\2
    \\-3
    \\3
    \\-2
    \\0
    \\4
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], 1, 1);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], 811589153, 10);
    try std.testing.expectEqual(@as(i64, 1623178306), result);
}
