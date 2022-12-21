const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const Operator = enum {
    add,
    sub,
    mul,
    div,
};

const MonkeyType = enum {
    math,
    yell,
};

const MathMonkey = struct {
    operand_a: []const u8,
    operand_b: []const u8,
    operator: Operator,
};

const YellMonkey = struct {
    val: i64,
};

const Monkey = union(MonkeyType) {
    math: MathMonkey,
    yell: YellMonkey,
};

fn solve(name: []const u8, ops: std.StringHashMap(Monkey)) i64 {
    const monkey = ops.get(name) orelse unreachable;
    return switch (monkey) {
        .yell => |m| m.val,
        .math => |m| blk: {
            break :blk switch (m.operator) {
                .add => solve(m.operand_a, ops) + solve(m.operand_b, ops),
                .sub => solve(m.operand_a, ops) - solve(m.operand_b, ops),
                .mul => solve(m.operand_a, ops) * solve(m.operand_b, ops),
                .div => @divFloor(solve(m.operand_a, ops), solve(m.operand_b, ops)),
            };
        },
    };
}

fn makeMonkeys(allocator: std.mem.Allocator, data: []const u8) !std.StringHashMap(Monkey) {
    var monkey_ops = std.StringHashMap(Monkey).init(allocator);

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        const tokens = try utils.strSplit(line, ":");
        // Assume if there are more than 8 chars it is a MathMonkey
        if (tokens[1].len > 8) {
            const a = tokens[1][1..5];
            const b = tokens[1][8..];
            const op: Operator = switch (tokens[1][6]) {
                '+' => .add,
                '-' => .sub,
                '*' => .mul,
                '/' => .div,
                else => unreachable,
            };
            try monkey_ops.putNoClobber(tokens[0], .{ .math = .{
                .operand_a = a,
                .operand_b = b,
                .operator = op,
            } });
        } else {
            const v = try std.fmt.parseInt(i64, tokens[1][1..], 10);
            try monkey_ops.putNoClobber(tokens[0], .{ .yell = .{ .val = v } });
        }
    }

    return monkey_ops;
}

fn findHumnOp(name: []const u8, ops: std.StringHashMap(Monkey)) ?Monkey {
    const monkey = ops.get(name) orelse unreachable;
    if (std.mem.eql(u8, name, "humn")) return monkey;
    return switch (monkey) {
        .yell => null,
        .math => |m| blk: {
            if (std.mem.eql(u8, m.operand_a, "humn")) return monkey;
            if (std.mem.eql(u8, m.operand_b, "humn")) return monkey;
            break :blk findHumnOp(m.operand_a, ops) orelse findHumnOp(m.operand_b, ops);
        },
    };
}

fn unsolve(name: []const u8, lhs: i64, ops: std.StringHashMap(Monkey)) i64 {
    const monkey = ops.get(name) orelse unreachable;
    switch (monkey) {
        .yell => |m| {
            return if (std.mem.eql(u8, "humn", name)) lhs else m.val;
        },
        .math => |m| {
            var a: ?i64 = null;
            var b: ?i64 = null;
            if (findHumnOp(m.operand_a, ops) == null) {
                a = solve(m.operand_a, ops);
            }
            if (findHumnOp(m.operand_b, ops) == null) {
                b = solve(m.operand_b, ops);
            }
            if (a == null and b == null) {
                return switch (m.operator) {
                    .add => solve(m.operand_a, ops) + solve(m.operand_b, ops),
                    .sub => solve(m.operand_a, ops) - solve(m.operand_b, ops),
                    .mul => solve(m.operand_a, ops) * solve(m.operand_b, ops),
                    .div => @divFloor(solve(m.operand_a, ops), solve(m.operand_b, ops)),
                };
            }
            if (a == null) {
                const b_val = solve(m.operand_b, ops);
                return switch (m.operator) {
                    .add => unsolve(m.operand_a, lhs - b_val, ops),
                    .sub => unsolve(m.operand_a, lhs + b_val, ops),
                    .mul => unsolve(m.operand_a, @divFloor(lhs, b_val), ops),
                    .div => unsolve(m.operand_a, lhs * b_val, ops),
                };
            }
            const a_val = solve(m.operand_a, ops);
            return switch (m.operator) {
                .add => unsolve(m.operand_b, lhs - a_val, ops),
                .sub => unsolve(m.operand_b, a_val - lhs, ops),
                .mul => unsolve(m.operand_b, @divFloor(lhs, a_val), ops),
                .div => unsolve(m.operand_b, @divFloor(a_val, lhs), ops),
            };
        },
    }
}

fn solve_1(allocator: std.mem.Allocator, data: []const u8) !i64 {
    var monkey_ops = try makeMonkeys(allocator, data);
    defer monkey_ops.deinit();

    return solve("root", monkey_ops);
}

fn solve_2(allocator: std.mem.Allocator, data: []const u8) !i64 {
    var monkey_ops = try makeMonkeys(allocator, data);
    defer monkey_ops.deinit();

    const root = monkey_ops.get("root") orelse unreachable;
    const a = root.math.operand_a;
    const b = root.math.operand_b;

    var humn_parent = findHumnOp(a, monkey_ops);

    var lhs: i64 = 0;
    var humn_side: []const u8 = undefined;
    if (humn_parent == null) {
        lhs = solve(a, monkey_ops);
        humn_side = b;
    } else {
        lhs = solve(b, monkey_ops);
        humn_side = a;
    }

    return unsolve(humn_side, lhs, monkey_ops);
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
    \\root: pppw + sjmn
    \\dbpl: 5
    \\cczh: sllz + lgvd
    \\zczc: 2
    \\ptdq: humn - dvpt
    \\dvpt: 3
    \\lfqf: 4
    \\humn: 5
    \\ljgn: 2
    \\sjmn: drzm * dbpl
    \\sllz: 4
    \\pppw: cczh / lfqf
    \\lgvd: ljgn * ptdq
    \\drzm: hmdt - zczc
    \\hmdt: 32
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve_1(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(i64, 152), result);
}

test "part_2" {
    std.debug.print("\n", .{});
    const result = try solve_2(std.testing.allocator, test_data[0..]);
    try std.testing.expectEqual(@as(i64, 301), result);
}
