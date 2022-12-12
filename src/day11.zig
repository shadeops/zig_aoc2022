const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const Operation = enum {
    add,
    multi,
    fn getOp(c: u8) Operation {
        return switch (c) {
            '+' => .add,
            '*' => .multi,
            else => unreachable,
        };
    }
};

const max_size = 32;

const Monkey = struct {
    queue: std.fifo.LinearFifo(u64, .{ .Static = max_size }),
    op: Operation,
    operand: ?u32,
    div: u32,
    true_target: u32,
    false_target: u32,
    worry_reduction: u32,
    handled: u32 = 0,

    fn toss(self: *Monkey, monkeys: *std.ArrayList(Monkey), factor: u64) !void {
        while (self.queue.readableLength() != 0) {
            var item = self.queue.readItem().?;
            item = self.handle(item) % factor;
            var exact = true;
            _ = std.math.divExact(u64, item, self.div) catch {
                exact = false;
            };
            if (exact) {
                try monkeys.items[self.true_target].queue.writeItem(item);
            } else {
                try monkeys.items[self.false_target].queue.writeItem(item);
            }
        }
    }

    fn handle(self: *Monkey, item: u64) u64 {
        self.handled += 1;
        return (switch (self.op) {
            .add => item + (self.operand orelse item),
            .multi => item * (self.operand orelse item),
        }) / self.worry_reduction;
    }
};

fn solver(allocator: std.mem.Allocator, data: []const u8, worry_level: u32, rounds: u32) !u64 {
    var monkeys = std.ArrayList(Monkey).init(allocator);
    defer monkeys.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");

    var monkey_num: u32 = 0;
    var next_line: []const u8 = undefined;
    var factor: u32 = 1;
    while (lines.next()) |line| {
        if (line[0] == 'M') {
            monkey_num = try std.fmt.parseUnsigned(u32, line[7..(line.len - 1)], 10);
            try monkeys.append(.{
                .queue = std.fifo.LinearFifo(u64, .{ .Static = max_size }).init(),
                .op = undefined,
                .operand = undefined,
                .div = undefined,
                .true_target = undefined,
                .false_target = undefined,
                .worry_reduction = worry_level,
            });
            // Starting Items
            next_line = lines.next() orelse return error.ParseError;
            var item_iter = std.mem.tokenize(u8, next_line[18..], ", ");
            while (item_iter.next()) |item| {
                var val = try std.fmt.parseUnsigned(u32, item, 10);
                try monkeys.items[monkey_num].queue.writeItem(val);
            }

            // Operation
            next_line = lines.next() orelse return error.ParseError;
            monkeys.items[monkey_num].op = Operation.getOp(next_line[23]);
            monkeys.items[monkey_num].operand = std.fmt.parseUnsigned(u32, next_line[25..], 10) catch null;

            // Test
            next_line = lines.next() orelse return error.ParseError;
            monkeys.items[monkey_num].div = try std.fmt.parseUnsigned(u32, next_line[21..], 10);
            factor *= monkeys.items[monkey_num].div;

            // True
            next_line = lines.next() orelse return error.ParseError;
            monkeys.items[monkey_num].true_target = try std.fmt.parseUnsigned(u32, next_line[29..], 10);

            // False
            next_line = lines.next() orelse return error.ParseError;
            monkeys.items[monkey_num].false_target = try std.fmt.parseUnsigned(u32, next_line[30..], 10);
        }
    }
    var round: u32 = 0;
    while (round < rounds) : (round += 1) {
        for (monkeys.items) |*monkey| {
            try monkey.toss(&monkeys, factor);
        }
    }
    var handled = std.ArrayList(u64).init(allocator);
    defer handled.deinit();
    for (monkeys.items) |monkey| {
        try handled.append(monkey.handled);
    }
    std.sort.sort(u64, handled.items, {}, comptime std.sort.desc(u64));

    return handled.items[0] * handled.items[1];
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
    try stdout.print("\tpart_1 = {}\n", .{try solver(allocator, data, 3, 20)});
    try stdout.print("\tpart_2 = {}\n", .{try solver(allocator, data, 1, 10000)});
    try stdout_bw.flush();
}

const test_data =
    \\Monkey 0:
    \\  Starting items: 79, 98
    \\  Operation: new = old * 19
    \\  Test: divisible by 23
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 3
    \\
    \\Monkey 1:
    \\  Starting items: 54, 65, 75, 74
    \\  Operation: new = old + 6
    \\  Test: divisible by 19
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 0
    \\
    \\Monkey 2:
    \\  Starting items: 79, 60, 97
    \\  Operation: new = old * old
    \\  Test: divisible by 13
    \\    If true: throw to monkey 1
    \\    If false: throw to monkey 3
    \\
    \\Monkey 3:
    \\  Starting items: 74
    \\  Operation: new = old + 3
    \\  Test: divisible by 17
    \\    If true: throw to monkey 0
    \\    If false: throw to monkey 1
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solver(std.testing.allocator, test_data[0..], 3, 20);
    try std.testing.expectEqual(@as(u64, 10605), result);
}
test "part_2" {
    std.debug.print("\n", .{});
    const result = try solver(std.testing.allocator, test_data[0..], 1, 10000);
    try std.testing.expectEqual(@as(u64, 2713310158), result);
}
