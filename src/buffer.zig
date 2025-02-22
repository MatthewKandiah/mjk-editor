const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListU8 = ArrayList(u8);
const Allocator = std.mem.Allocator;
const io = std.io;
const AnyReader = io.AnyReader;
const AnyWriter = io.AnyWriter;
const platform = @import("platform.zig");
const Position = @import("position.zig").Position;

pub const Buffer = struct {
    data: ArrayList(ArrayList(u8)),
    allocator: Allocator,
    cursor_pos: Position,
    mode: Mode,

    const Self = @This();

    pub const Mode = enum {
        Normal,
        Insert,
    };

    pub fn init(allocator: Allocator, reader: AnyReader) !Self {
        var lines = ArrayList(ArrayListU8).init(allocator);
        while (true) {
            var line = ArrayListU8.init(allocator);
            reader.streamUntilDelimiter(line.writer().any(), '\n', null) catch |err| {
                if (err == error.EndOfStream) {
                    return Self{
                        .data = lines,
                        .allocator = allocator,
                        .cursor_pos = .{ .x = 0, .y = 0 },
                        .mode = .Normal,
                    };
                } else {
                    return err;
                }
            };
            try lines.append(line);
        }
        // TODO-Matt: probably need to add an empty line if the input is empty, or we won't be able to position the cursor
    }

    pub fn write(self: Self, writer: AnyWriter) !void {
        const lines = self.data.items;
        for (lines, 0..) |line, i| {
            try writer.writeAll(line.items);
            if (i != lines.len - 1) try writer.writeAll("\n");
        }
    }

    pub fn handleMoveLeft(self: *Self) void {
        if (self.cursor_pos.x == 0) return;
        self.cursor_pos.x -= 1;
    }

    pub fn handleMoveUp(self: *Self) void {
        if (self.cursor_pos.y == 0) return;
        self.cursor_pos.y -= 1;
    }

    pub fn handleMoveRight(self: *Self) void {
        if (self.cursor_pos.x + 1 >= self.data.items[self.cursor_pos.y].items.len) return;
        self.cursor_pos.x += 1;
    }

    pub fn handleMoveDown(self: *Self) void {
        if (self.cursor_pos.y + 1 >= self.data.items.len) return;
        self.cursor_pos.y += 1;
    }
};
