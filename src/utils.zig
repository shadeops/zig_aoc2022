const std = @import("std");

pub fn str_split(buf: []const u8, delimiter: []const u8) ![2][]const u8 {
    var ret = [_][]const u8{undefined} ** 2;
    var token_iter = std.mem.tokenize(u8, buf, delimiter);
    ret[0] = token_iter.next() orelse return error.SplitError;
    ret[1] = token_iter.next() orelse return error.SplitError;
    if (token_iter.next() != null) return error.SplitError;
    return ret;
}
