const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListU8 = ArrayList(u8);
const Allocator = std.mem.Allocator;
const io = std.io;
const AnyReader = io.AnyReader;
const AnyWriter = io.AnyWriter;
const platform = @import("platform.zig");

pub const Buffer = struct {
    data: ArrayList(ArrayList(u8)),
    allocator: Allocator,

    const Self = @This();

    pub fn init(allocator: Allocator, reader: AnyReader) !Self {
        var lines = ArrayList(ArrayListU8).init(allocator);
        var running = true;
        while (running) {
            var line = ArrayListU8.init(allocator);
            reader.streamUntilDelimiter(line.writer().any(), '\n', null) catch |err| {
                if (err == error.EndOfStream) {
                    running = false;
                } else {
                    return err;
                }
            };
            try lines.append(line);
        }
        return Self{
            .data = lines,
            .allocator = allocator,
        };
    }

    pub fn write(self: Self, writer: AnyWriter) !void {
        const lines = self.data.items;
        for (lines, 0..) |line, i| {
            try writer.writeAll(line.items);
            if (i != lines.len - 1) try writer.writeAll("\n");
        }
    }
};
