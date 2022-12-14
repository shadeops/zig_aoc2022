const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

fn getList(str: []const u8) ![]const u8 {
    var count: usize = 0;
    var end = blk: for (str) |c,i| {
        switch (c) {
            '[' => count +=1,
            ']' => {
                count -=1;
                if (count == 0) break :blk i+1;
            },
            else => continue,
        }
    } else {
        return error.ParseError;
    };
    return str[0..end];
}

const ListIterator = struct {
    index: usize = 0,
    str: []const u8,

    fn next(self: *ListIterator) ?[]const u8 {

        if (self.index >= self.str.len) {
            return null; 
        }

        for (self.str[self.index .. self.str.len-1]) |c,i| {
            switch (c) {
                '[' => { 
                    var sub_list = getList(self.str[self.index+i..]) catch unreachable;
                    self.index += sub_list.len;
                    // We could be at the so we need to check if there is more after
                    // what we got from the sub_list.
                    if (self.index < self.str.len-1) {
                        self.index += 1;
                    }
                    return sub_list;
                },
                ']' => unreachable, //unbalanced parens
                ',' => {
                    var val = self.str[self.index .. self.index+i];
                    self.index = self.index+i+1;
                    return val;
                },
                '0'...'9' => continue,
                else => unreachable, // something bad
            }
        }
        defer self.index = self.str.len;
        return self.str[self.index..];
    }

    fn reset(self: *ListIterator) void {
        self.index = 0;
    }
};

fn listIterator(str: []const u8) ListIterator {
    if (str[0] == '[' and str[str.len-1] == ']')
        return .{.str = str[1..str.len-1]};
    return .{.str = str};
}

// Here our compare function returns true if left is less than
// or false if greater than. But we also return null to mean
// matching/equal values and that we shoudl continue searching.
//
// TODO, better form would be to use an enum of
//  .greater
//  .less
//  .eql
//  and return those values to compare against instead of using
//  and optional bool.
fn compare(left: []const u8, right: []const u8) !?bool {
  
    var left_iter = listIterator(left);
    var right_iter = listIterator(right);

    while (true) {
        var l = left_iter.next();
        var r = right_iter.next();

        if (l == null and r == null) break;
        if (l == null and r != null) return true;
        if (l != null and r == null) return false;

        if (l.?[0] == '[' and r.?[0] == '[') {
            return (try compare(l.?, r.?)) orelse continue;
        }
        
        // mixed
        if (l.?[0] == '[' or r.?[0] == '[') {
            return (try compare(l.?, r.?)) orelse continue;
        }
        
        var l_val = try std.fmt.parseUnsigned(u32, l.?, 10);
        var r_val = try std.fmt.parseUnsigned(u32, r.?, 10);
        
        if (l_val > r_val) {
            return false;
        }
        
        if (l_val < r_val) {
            return true;
        }
    }

    return null;
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !u64 {
    _ = allocator;

    var lines = std.mem.tokenize(u8, data, "\n");
    var valid: u32 = 0;
    var num: u32 = 1;
    while (lines.next()) |line| {
        const left = line;
        const right = lines.next().?;
        if ((try compare(left, right)).?) {
            valid += num;
        }
        num += 1;
    }
    return valid;
}


fn lessThan(context: void, a: []const u8, b: []const u8) bool {
    _ = context;
    return (compare(a, b) catch false) orelse false;
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !u64 {

    var msgs = std.ArrayList([]const u8).init(allocator);
    defer msgs.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        try msgs.append(line);
    }
    try msgs.append("[[2]]");
    try msgs.append("[[6]]");

    std.sort.sort([]const u8, msgs.items, {}, lessThan); 
    var total: usize = 1;
    for (msgs.items) |item,i| {
        if (std.mem.eql(u8, item, "[[2]]")) total *= i+1;
        if (std.mem.eql(u8, item, "[[6]]")) total *= i+1;
    }

    return total;
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
    \\[1,1,3,1,1]
    \\[1,1,5,1,1]
    \\
    \\[[1],[2,3,4]]
    \\[[1],4]
    \\
    \\[9]
    \\[[8,7,6]]
    \\
    \\[[4,4],4,4]
    \\[[4,4],4,4,4]
    \\
    \\[7,7,7,7]
    \\[7,7,7]
    \\
    \\[]
    \\[3]
    \\
    \\[[[]]]
    \\[[]]
    \\
    \\[1,[2,[3,[4,[5,6,7]]]],8,9]
    \\[1,[2,[3,[4,[5,6,0]]]],8,9]
;

test "getLength" {
    const a = "[[1],[2,3,4]]";
    const b = "[[1],2,3],4]]";
    std.debug.print("{s}\n", .{try getList(a[0..])});
    std.debug.print("{s}\n", .{try getList(a[1..])});
    std.debug.print("{s}\n", .{try getList(b[0..])});
}

test "listIter" {
    std.debug.print("listIter\n", .{});
    const a = "[1,2,33,4,[5,10]]";
    var iter = listIterator(a);
    try std.testing.expectEqual(@as(u32, 1), try std.fmt.parseUnsigned(u32, iter.next().?, 10));
    try std.testing.expectEqual(@as(u32, 2), try std.fmt.parseUnsigned(u32, iter.next().?, 10));
    try std.testing.expectEqual(@as(u32, 33), try std.fmt.parseUnsigned(u32, iter.next().?, 10));
    try std.testing.expectEqual(@as(u32, 4), try std.fmt.parseUnsigned(u32, iter.next().?, 10));
    try std.testing.expectEqualSlices(u8, "[5,10]", iter.next().?);
    try std.testing.expectEqual(iter.next(), null);
}

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 13), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(u64, 0), result);
}
