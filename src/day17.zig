const std = @import("std");
const utils = @import("utils.zig");

const unit_name = @typeName(@This());
const data_path = &("data/".* ++ unit_name.*);

const Row = std.StaticBitSet(7);

const debug = false;
const more_debug = false;
const final_result = false;

fn movePiece(move: u8, piece: []Row) void {
    switch (move) {
        '<' => {
            for (piece) |*row| {
                row.mask <<= 1;
            }
        },
        '>' => {
            for (piece) |*row| {
                row.mask >>= 1;
            }
        },
        else => unreachable,
    }
}

fn canMove(move: u8, piece: []Row, base_row: usize, board: std.ArrayList(Row)) bool {
    for (piece) |row, i| {
        var moved_row = row;
        if (base_row + i >= board.items.len) continue;
        switch (move) {
            '<' => {
                if (row.isSet(6)) return false;
                moved_row.mask <<= 1;
            },
            '>' => {
                if (row.isSet(0)) return false;
                moved_row.mask >>= 1;
            },
            else => unreachable,
        }
        if (moved_row.intersectWith(board.items[base_row + i]).mask != 0) {
            // we hit something and are overlapping, move back a row and stop
            //std.debug.print("collision to {c} on row: {}\n", .{move, base_row + i});
            return false;
        }
    }
    return true;
}

fn printBoard(board: []const Row) void { 
    var i: usize = 0;
    var iter = std.mem.reverseIterator(board);
    while (iter.next()) |row| {
        std.debug.print("[{:4}] ", .{board.len - i});
        var b: usize = 7;
        while (b > 0) {
            b -= 1;
            if (row.isSet(b)) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
        i += 1;
    }
    std.debug.print("\n", .{});
}

fn solve(allocator: std.mem.Allocator, data: []const u8, steps: u64) !u64 {

    // 6543210
    //   ####
    var horizontal = [_]Row{Row.initEmpty()} ** 1;
    horizontal[0].setRangeValue(.{ .start = 1, .end = 5 }, true);

    // 6543210
    //    #
    //   ###
    //    #
    var plus = [_]Row{Row.initEmpty()} ** 3;
    plus[2].set(3);
    plus[1].setRangeValue(.{ .start = 2, .end = 5 }, true);
    plus[0].set(3);

    // 6543210
    //    #
    //    #
    //  ###
    var L = [_]Row{Row.initEmpty()} ** 3;
    L[2].set(2);
    L[1].set(2);
    L[0].setRangeValue(.{ .start = 2, .end = 5 }, true);

    // 6543210
    //   #
    //   #
    //   #
    //   #
    var vertical = [_]Row{Row.initEmpty()} ** 4;
    vertical[0].set(4);
    vertical[1].set(4);
    vertical[2].set(4);
    vertical[3].set(4);

    // 6543210
    //   ##
    //   ##
    var square = [_]Row{Row.initEmpty()} ** 2;
    square[0].setRangeValue(.{ .start = 3, .end = 5 }, true);
    square[1].setRangeValue(.{ .start = 3, .end = 5 }, true);

    var pieces = std.ArrayList([]const Row).init(allocator);
    defer pieces.deinit();
    try pieces.append(horizontal[0..]);
    try pieces.append(plus[0..]);
    try pieces.append(L[0..]);
    try pieces.append(vertical[0..]);
    try pieces.append(square[0..]);

    if (false) {
        for (pieces.items) |piece| {
            var iter = std.mem.reverseIterator(piece);
            while (iter.next()) |row| {
                std.debug.print("{b:0>7}\n", .{row.mask});
            }
            std.debug.print("\n", .{});
        }
    }

    var board = std.ArrayList(Row).init(allocator);
    defer board.deinit();

    //try board.append(Row.initEmpty());
    //try board.append(Row.initEmpty());
    //try board.append(Row.initEmpty());
    var active_row: usize = 0;

    var moves = std.ArrayList(u8).init(allocator);
    defer moves.deinit();

    var lines = std.mem.tokenize(u8, data, "\n");
    while (lines.next()) |line| {
        try moves.appendSlice(line);
    }

    var piece_buffer = [_]Row{Row.initEmpty()} ** 4;
    var count: u64 = 0;
    var current_piece: usize = 0;
    var current_move: usize = 0;

    var current_top: usize = 0;
    while (count < steps) : (count += 1) {
        defer {
            current_piece += 1;
            current_piece %= pieces.items.len;
        }
        if (debug) {
            std.debug.print("Piece Drop Count: {}\n", .{count});
            std.debug.print("\tCurrent Top: {} / {}\n", .{ current_top, board.items.len });
        }

        if ((count % 1000000) + 1 == 1000000) std.debug.print("{}\n", .{count});
        for (pieces.items[current_piece]) |row, i| {
            piece_buffer[i] = row;
        }
        var piece = piece_buffer[0..pieces.items[current_piece].len];

        // Add pad of 3
        //var clearance: usize = if (board.items.len > 0) board.items.len - (current_top + 1) else 0;
        var clearance: usize = 0;
        {
            var iter = std.mem.reverseIterator(board.items);
            while (iter.next()) |row| {
                if (row.mask != 0) break;
                clearance += 1;
            }
            var pad_required: usize = 0;
            if (clearance < 3)
                pad_required = 3 - clearance;
            if (debug) std.debug.print("Adding padding of {} {} {}\n", .{ pad_required, clearance, board.items.len - current_top });
            while (pad_required > 0) : (pad_required -= 1) try board.append(Row.initEmpty());
        }

        // Pad for new piece
        if (clearance <= 3) {
            try board.append(Row.initEmpty());
            active_row = board.items.len - 1;
        } else {
            active_row = board.items.len - (clearance - 3);
        }

        // Start checking the board.
        var mode: u8 = 0;
        halt: while (true) {
            defer {
                if (more_debug) {
                    std.debug.print("mode: {}\n", .{mode});
                    var iter = std.mem.reverseIterator(board.items);
                    var print_row: usize = board.items.len;
                    while (iter.next()) |row| {
                        print_row -= 1;
                        var mask = row.mask;
                        // active_row is the bottom of piece
                        // print_row is the row being printed
                        // if the row being printed is greater than or equal to the
                        // active row AND print_row is less than the active_row + piece.len
                        var piece_top = active_row + piece.len;
                        //std.debug.print("{} {} {} {}\n", .{print_row, active_row, piece_top, piece.len});
                        if (print_row < piece_top and print_row >= active_row) {
                            mask |= piece[print_row - active_row].mask;
                        }
                        var bset = Row.initEmpty();
                        bset.mask = mask;
                        std.debug.print("[{:3}]: ", .{print_row});
                        var b: usize = 7;
                        while (b > 0) {
                            b -= 1;
                            if (bset.isSet(b)) {
                                std.debug.print("#", .{});
                            } else {
                                std.debug.print(".", .{});
                            }
                        }
                        std.debug.print("\n", .{});
                    }
                    std.debug.print("\n", .{});
                }
                mode += 1;
                mode %= 2;
            }
            if (mode == 0) {
                // move the piece left or right
                var move = moves.items[current_move];
                if (more_debug) {
                    std.debug.print("active_row: {}\n{s}\n", .{ active_row, moves.items });
                    var i: usize = 0;
                    while (i < moves.items.len) : (i += 1) {
                        if (i == current_move) {
                            std.debug.print("*", .{});
                        } else {
                            std.debug.print(" ", .{});
                        }
                    }
                    std.debug.print("\n", .{});
                }
                current_move += 1;
                current_move %= moves.items.len;

                if (canMove(move, piece, active_row, board))
                    movePiece(move, piece);
                continue;
            } else {
                // drop the piece down one row and check.
                if (active_row == 0) break :halt;
                for (piece) |row, i| {
                    if (active_row + i >= board.items.len) continue;
                    if (row.intersectWith(board.items[active_row + i - 1]).mask != 0) {
                        // we hit something and are overlapping, move back a row and stop
                        if (more_debug) std.debug.print("collision on row: {}\n", .{active_row});
                        break :halt;
                    }
                    if (active_row == 0) break :halt;
                }
                active_row -= 1;
            }
        }

        // We got here either by hitting the bottom, or halting

        // Place the piece
        for (piece) |row, i| {
            board.items[active_row + i].setUnion(row);
        }

        if (debug) {
            printBoard(board.items);
        }
    }

    var height = brk: for (board.items) |row, i| {
        if (row.mask == 0) break :brk i;
    } else {
        unreachable;
    };

    if (final_result) {
        printBoard(board.items);
    }

    return @intCast(u64, height);
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
    try stdout.print("\tpart_1 = {}\n", .{try solve(allocator, data, 2022)});
    //try stdout.print("\tpart_2 = {}\n", .{try solve(allocator, data, 1000000000000)});
    try stdout_bw.flush();
}

const test_data =
    \\>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>
;

test "part_1" {
    std.debug.print("\n", .{});
    const result = try solve(std.testing.allocator, test_data[0..], 2022);
    try std.testing.expectEqual(@as(u64, 3068), result);
}

//test "part_2" {
//    std.debug.print("\n", .{});
//    const result = try solve(std.testing.allocator, test_data[0..], 1000000000000);
//    try std.testing.expectEqual(@as(u64, 1514285714288), result);
//}
