const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListU8 = ArrayList(u8);
const Allocator = std.mem.Allocator;

pub const Buffer = struct {
    data: ArrayList(ArrayList(u8)),
    allocator: Allocator,

    const Self = @This();

    pub fn init(allocator: Allocator, reader: std.io.AnyReader) !Self {
        var lines = ArrayList(ArrayListU8).init(allocator);
        while (true) {
            var line = ArrayListU8.init(allocator);
            // TODO-Matt: handle EndOfStream error
            try reader.streamUntilDelimiter(line.writer().any(), '\n', null);
            try lines.append(line);
        }
        return Self{
            .data = lines,
            .allocator = allocator,
        };
    }
};
