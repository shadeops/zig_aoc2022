const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const grid_res = 32;
const total_voxels = grid_res * grid_res * grid_res;

const Coord = struct {
    x: u32,
    y: u32,
    z: u32,
};

fn xyzToOffset(c: Coord) usize {
    // 1,0,0 = 1
    // 0,1,0 = xres + 1
    // 0,2,0 = xres * 2
    // 0,0,1 = xres * xres
    // 0,1,1 = xres * xres * z  + xres * y + x
    return grid_res * grid_res * c.z + grid_res * c.y + c.x;
}

fn offsetToXYZ(offset: usize) Coord {
    return .{
        .x = @intCast(u32, offset) % grid_res,
        .y = (@intCast(u32, offset) / grid_res) % grid_res,
        .z = @intCast(u32, offset) / (grid_res * grid_res),
    };
}

const NeighbourIterator = struct {
    index: usize = 0,
    offset: usize,

    fn next(self: *NeighbourIterator) ?usize {
        var coord = offsetToXYZ(self.offset);
        var x: i32 = @intCast(i32, coord.x);
        var y: i32 = @intCast(i32, coord.y);
        var z: i32 = @intCast(i32, coord.z);

        switch (self.index) {
            0 => x += 1,
            1 => x -= 1,
            2 => y += 1,
            3 => y -= 1,
            4 => z += 1,
            5 => z -= 1,
            else => return null,
        }
        self.index += 1;
        if (x < 0 or x >= grid_res or y < 0 or y >= grid_res or z < 0 or z >= grid_res) return self.next();
        return xyzToOffset(.{
            .x = @intCast(u32, x),
            .y = @intCast(u32, y),
            .z = @intCast(u32, z),
        });
    }
};

fn neighbourIterator(offset: usize) NeighbourIterator {
    return NeighbourIterator{
        .offset = offset,
    };
}

fn full_scan(voxels: []const bool) !u64 {
    var surface: u32 = 0;
    for (voxels) |voxel, i| {
        if (!voxel) continue;
        var iter = neighbourIterator(i);
        while (iter.next()) |offset| {
            if (!voxels[offset]) {
                surface += 1;
                continue;
            }
        }
    }
    //std.debug.assert(surface != 4442);
    return surface;
}

fn exterior_scan(allocator: std.mem.Allocator, voxels: []const bool) !u64 {

    // NOTES: Could be optimized with various flood fill algorithms
    var checked_voxels = try allocator.alloc(bool, voxels.len);
    defer allocator.free(checked_voxels);
    for (checked_voxels) |*voxel| voxel.* = false;

    var queue = std.ArrayList(usize).init(allocator);
    defer queue.deinit();

    var surface: u32 = 0;

    // start scan of empty connected voxels
    try queue.append(0);
    while (queue.items.len != 0) {
        var voxel = queue.pop();

        // we may have added the voxel to the queue multiple times
        // before actually getting to it, so we need to skip if it
        // has been processed already.
        if (checked_voxels[voxel]) continue;

        // if it isn't empty, skip
        if (voxels[voxel]) continue;

        // add neighbours to the queue.
        var iter = neighbourIterator(voxel);
        while (iter.next()) |offset| {
            // skip active voxels
            if (voxels[offset]) {
                surface += 1;
                continue;
            }
            // if already scanned continue
            if (checked_voxels[offset]) continue;

            // otherwise add it to the queue
            try queue.append(offset);
        }
        checked_voxels[voxel] = true;
    }

    return surface;
}

fn solve(allocator: std.mem.Allocator, data: []const u8, interior: bool) !u64 {
    var voxels = try allocator.alloc(bool, total_voxels);
    defer allocator.free(voxels);
    for (voxels) |*voxel| voxel.* = false;

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        var iter = std.mem.tokenize(u8, line, ",");
        // We have to add +1 to account for voxels at 0 which count as still being
        // next to things.
        const x = try std.fmt.parseUnsigned(u32, iter.next().?, 10) + 1;
        const y = try std.fmt.parseUnsigned(u32, iter.next().?, 10) + 1;
        const z = try std.fmt.parseUnsigned(u32, iter.next().?, 10) + 1;
        const coord = Coord{ .x = x, .y = y, .z = z };
        voxels[xyzToOffset(coord)] = true;
    }

    if (interior)
        return full_scan(voxels);
    return exterior_scan(allocator, voxels);
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
    \\2,2,2
    \\1,2,2
    \\3,2,2
    \\2,1,2
    \\2,3,2
    \\2,2,1
    \\2,2,3
    \\2,2,4
    \\2,2,6
    \\1,2,5
    \\3,2,5
    \\2,1,5
    \\2,3,5
;

test "voxels" {
    var c = Coord{ .x = 5, .y = 0, .z = 0 };
    var offset = xyzToOffset(c);
    try std.testing.expectEqual(@as(usize, 5), offset);
    try std.testing.expectEqual(c, offsetToXYZ(offset));
    c = .{ .x = 0, .y = 1, .z = 1 };
    try std.testing.expectEqual(c, offsetToXYZ(32 * 32 + 32));
    c = .{ .x = 31, .y = 31, .z = 31 };
    try std.testing.expectEqual(c, offsetToXYZ(32 * 32 * 32 - 1));
    try std.testing.expectEqual(@as(usize, 32 * 32 * 32 - 1), xyzToOffset(c));
}

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], true);
    try std.testing.expectEqual(@as(u64, 64), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], false);
    try std.testing.expectEqual(@as(u64, 58), result);
}
