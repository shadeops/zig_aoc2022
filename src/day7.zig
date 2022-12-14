const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const NodeType = enum {
    file,
    dir,
};

const Dir = struct {
    nodes: std.ArrayList(*INode),
};

const File = struct {
    size: u32,
};

const Node = union(NodeType) {
    file: File,
    dir: Dir,
};

const INode = struct {
    name: []const u8,
    node: Node,
    parent: ?*INode = null,

    fn mkdir(self: *INode, allocator: std.mem.Allocator, name: []const u8) !*INode {
        var new_dir = try allocator.create(INode);
        new_dir.* = .{
            .name = name,
            .parent = self,
            .node = .{ .dir = .{ .nodes = std.ArrayList(*INode).init(allocator) } },
        };
        //std.debug.print("mkdir {s}\n", .{name});
        return new_dir;
    }

    fn mkfile(self: *INode, allocator: std.mem.Allocator, name: []const u8, size: u32) !*INode {
        var new_file = try allocator.create(INode);
        new_file.* = .{
            .name = name,
            .parent = self,
            .node = .{ .file = .{ .size = size } },
        };
        //std.debug.print("mkfile {s} {}\n", .{name, size});
        return new_file;
    }

    fn cd(self: *const INode, name: []const u8) !*INode {
        if (name[0] == '.') {
            //std.debug.print("cd .. [{s}]\n", .{self.parent.?.name});
            return self.parent orelse error.NoParent;
        }

        for (self.node.dir.nodes.items) |inode| {
            if (std.mem.eql(u8, inode.name, name)) {
                //std.debug.print("cd {s}\n", .{name});
                return inode;
            }
        }
        return error.MissingFile;
    }

    fn spaceUsed(self: INode) u32 {
        switch (self.node) {
            .file => |file| {
                return file.size;
            },
            .dir => |dir| {
                if (dir.nodes.items.len == 0) {
                    return 0;
                }
                var sum: u32 = 0;
                for (dir.nodes.items) |node| {
                    sum += node.spaceUsed();
                }
                return sum;
            },
        }
    }

    fn deinit(self: INode, allocator: std.mem.Allocator) void {
        switch (self.node) {
            .file => {
                return;
            },
            .dir => |dir| {
                if (dir.nodes.items.len == 0) {
                    return;
                }
                for (dir.nodes.items) |node| {
                    node.deinit(allocator);
                    allocator.destroy(node);
                }
                dir.nodes.deinit();
            },
        }
    }
};

fn atMost(inode: *const INode, limit: u32, tally: *u32) u32 {
    switch (inode.node) {
        .file => |file| {
            return file.size;
        },
        .dir => |dir| {
            if (dir.nodes.items.len == 0) {
                return 0;
            }
            var sum: u32 = 0;
            for (dir.nodes.items) |node| {
                sum += atMost(node, limit, tally);
            }
            if (sum <= limit) tally.* += sum;
            return sum;
        },
    }
}

fn findCapacity(inode: *const INode, size: u32, tally: *u32) u32 {
    switch (inode.node) {
        .file => |file| {
            return file.size;
        },
        .dir => |dir| {
            if (dir.nodes.items.len == 0) {
                return 0;
            }
            var sum: u32 = 0;
            for (dir.nodes.items) |node| {
                sum += findCapacity(node, size, tally);
            }
            if (sum >= size) tally.* = @min(tally.*, sum);
            return sum;
        },
    }
}

fn build_fs(allocator: std.mem.Allocator, data: []const u8) !*const INode {
    const root = try allocator.create(INode);

    root.* = .{
        .name = "/",
        .node = .{ .dir = .{ .nodes = std.ArrayList(*INode).init(allocator) } },
    };

    var lines = std.mem.tokenize(u8, data, "\n");
    var cwd: *INode = root;
    while (lines.next()) |line| {
        if (line[0] == '$') {
            switch (line[2]) {
                'c' => {
                    if (line[5] == '/') {
                        cwd = root;
                        continue;
                    }
                    cwd = try cwd.cd(line[5..]);
                },
                'l' => continue,
                else => return error.UnknownCmd,
            }
        } else if (line[0] == 'd') {
            var new_dir: *INode = try cwd.mkdir(allocator, line[4..]);
            try cwd.node.dir.nodes.append(new_dir);
        } else {
            var tokens = try utils.strSplit(line, " ");
            var file_size = try std.fmt.parseUnsigned(u32, tokens[0], 10);
            var new_file = try cwd.mkfile(allocator, tokens[1], file_size);
            try cwd.node.dir.nodes.append(new_file);
        }
    }
    return root;
}

fn solve_1(inode: *const INode) u32 {
    var tally: u32 = 0;
    _ = atMost(inode, 100000, &tally);
    return tally;
}

fn solve_2(inode: *const INode) u32 {
    var used = inode.spaceUsed();
    var unused = (70000000 - used);
    var needed = 30000000 - unused;
    var tally: u32 = used;
    _ = findCapacity(inode, needed, &tally);
    return tally;
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

    const root = try build_fs(allocator, data);
    defer {
        root.deinit(allocator);
        allocator.destroy(root);
    }

    try stdout.print("\tpart_1 = {}\n", .{solve_1(root)});
    try stdout.print("\tpart_2 = {}\n", .{solve_2(root)});
    try stdout_bw.flush();
}

const test_data =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

test "part_1" {
    const root = try build_fs(std.testing.allocator, test_data[0..]);
    defer {
        root.deinit(std.testing.allocator);
        std.testing.allocator.destroy(root);
    }
    const result = solve_1(root);
    try std.testing.expectEqual(@as(u64, 95437), result);
}

test "total_used" {
    const root = try build_fs(std.testing.allocator, test_data[0..]);
    defer {
        root.deinit(std.testing.allocator);
        std.testing.allocator.destroy(root);
    }
    try std.testing.expectEqual(@as(u32, 48381165), root.spaceUsed());
}

test "part_2" {
    const root = try build_fs(std.testing.allocator, test_data[0..]);
    defer {
        root.deinit(std.testing.allocator);
        std.testing.allocator.destroy(root);
    }
    const result = solve_2(root);
    try std.testing.expectEqual(@as(u32, 24933642), result);
}

// Various notes
//  * Dir could use StringHashMap instead of ArrayList
//  * Ideally there would be a single deinit for the root and tree
//  Alternative Implementations:
//      Since all the directories have unique names there isn't
//      really a need to maintain a tree structure. And a flat
//      map would suffice.

