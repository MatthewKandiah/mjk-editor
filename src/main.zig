const std = @import("std");
const lib = @import("./lib.zig");

pub fn main() !void {
    const a = 1;
    const b = 2;
    const c = lib.add(a, b);
    std.debug.print("{} + {} = {}\n", .{ a, b, c });
}
