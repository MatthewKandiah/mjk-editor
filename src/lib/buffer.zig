const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListU8 = ArrayList(u8);
const Allocator = std.mem.Allocator;
const io = std.io;
const AnyReader = io.AnyReader;
const AnyWriter = io.AnyWriter;
const platform = @import("platform.zig");
const Position = @import("position.zig").Position;
const Font = @import("font.zig").Font;
const Utf8String = @import("unicodeString.zig").Utf8String;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Buffer = struct {
    data: ArrayList(ArrayListU8),
    char_widths: ArrayList(ArrayList(usize)),
    allocator: Allocator,
    cursor_pos: Position,
    target_x_position: usize,
    font: *Font,
    font_size: usize,
    mode: Mode,

    const Self = @This();

    pub const Mode = enum {
        Normal,
        Insert,
    };

    pub fn init(allocator: Allocator, reader: AnyReader, font: *Font, font_size: usize) !Self {
        var lines = ArrayList(ArrayListU8).init(allocator);
        var char_widths = ArrayList(ArrayList(usize)).init(allocator);
        while (true) {
            var line = ArrayListU8.init(allocator);
            reader.streamUntilDelimiter(line.writer().any(), '\n', null) catch |err| {
                if (err == error.EndOfStream) {
                    return Self{
                        .data = lines,
                        .char_widths = char_widths,
                        .allocator = allocator,
                        .cursor_pos = .{ .x = 0, .y = 0 },
                        .target_x_position = 0,
                        .mode = .Normal,
                        .font = font,
                        .font_size = font_size,
                    };
                } else {
                    return err;
                }
            };
            const utf8_string = Utf8String{ .data = line.items };
            var utf8_iter = try utf8_string.iterate();
            var glyph = utf8_iter.next();
            var line_char_widths = ArrayList(usize).init(allocator);
            while (glyph != null) : (glyph = utf8_iter.next()) {
                const glyph_info = try font.get(glyph.?);
                try line_char_widths.append(glyph_info.width);
            }

            try lines.append(line);
            try char_widths.append(line_char_widths);
        }
        // TODO-Matt: probably need to add an empty line if the input is empty, or we won't be able to position the cursor
    }

    pub fn flushUserEvents(self: *Self, p: *platform.Platform) bool {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                return false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                p.handleWindowResized();
            } else if (event.type == c.SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => return false,
                    c.SDLK_UP => self.handleMoveUp(),
                    c.SDLK_DOWN => self.handleMoveDown(),
                    c.SDLK_LEFT => self.handleMoveLeft(),
                    c.SDLK_RIGHT => self.handleMoveRight(),
                    c.SDLK_i => self.mode = .Insert,
                    c.SDLK_n => self.switchToNormal(),
                    else => p.print("Unhandled keypress\n", .{}),
                }
            }
        }
        return true;
    }

    pub fn write(self: Self, writer: AnyWriter) !void {
        const lines = self.data.items;
        for (lines, 0..) |line, i| {
            try writer.writeAll(line.items);
            if (i != lines.len - 1) try writer.writeAll("\n");
        }
    }

    fn maxXPos(self: Self) usize {
        return if (self.mode == .Insert) self.data.items[self.cursor_pos.y].items.len + 1 else self.data.items[self.cursor_pos.y].items.len;
    }

    pub fn handleMoveLeft(self: *Self) void {
        if (self.cursor_pos.x == 0) return;
        self.cursor_pos.x -= 1;
        self.updateTargetXPosition();
    }

    pub fn handleMoveRight(self: *Self) void {
        if (self.cursor_pos.x + 1 >= self.maxXPos()) return;
        self.cursor_pos.x += 1;
        self.updateTargetXPosition();
    }

    fn updateTargetXPosition(self: *Self) void {
        self.target_x_position = 0;
        for (0..self.cursor_pos.x) |i| {
            self.target_x_position += self.char_widths.items[self.cursor_pos.y].items[i];
        }
        if (self.cursor_pos.x < self.char_widths.items[self.cursor_pos.y].items.len) {
            self.target_x_position += self.char_widths.items[self.cursor_pos.y].items[self.cursor_pos.x] / 2;
        }
    }

    pub fn handleMoveUp(self: *Self) void {
        if (self.cursor_pos.y == 0) return;
        self.cursor_pos.y -= 1;
        self.setCursorToTargetX();
    }

    pub fn handleMoveDown(self: *Self) void {
        if (self.cursor_pos.y + 1 >= self.data.items.len) return;
        self.cursor_pos.y += 1;
        self.setCursorToTargetX();
    }

    fn setCursorToTargetX(self: *Self) void {
        var x_pos: usize = 0;
        var x_displacement: usize = 0;

        if (self.mode == .Insert) {
            var total_width: usize = 0;
            for (self.char_widths.items[self.cursor_pos.y].items) |width| {
                total_width += width;
            }
            if (self.target_x_position >= total_width) {
                self.cursor_pos.x = self.data.items[self.cursor_pos.y].items.len;
                return;
            }
        }

        while (x_pos < self.data.items[self.cursor_pos.y].items.len) {
            x_displacement += self.char_widths.items[self.cursor_pos.y].items[x_pos];
            if (x_displacement > self.target_x_position) {
                break;
            }
            if (x_pos == self.data.items[self.cursor_pos.y].items.len - 1) {
                break;
            }
            x_pos += 1;
        }
        self.cursor_pos.x = x_pos;
    }

    pub fn switchToNormal(self: *Self) void {
        self.mode = .Normal;
        self.setCursorToTargetX();
    }
};
