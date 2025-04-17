const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListU8 = ArrayList(u8);
const Allocator = std.mem.Allocator;
const io = std.io;
const unicode = std.unicode;
const AnyReader = io.AnyReader;
const AnyWriter = io.AnyWriter;
const platform = @import("platform.zig");
const Position = @import("position.zig").Position;
const Font = @import("font.zig").Font;
const Utf8String = @import("unicodeString.zig").Utf8String;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

// TODO-Matt: support multiple open buffers
pub const Buffer = struct {
    data: ArrayList(ArrayListU8),
    char_widths: ArrayList(ArrayList(usize)),
    allocator: Allocator,
    cursor_pos: Position,
    target_x_position: usize,
    font: *Font,
    font_size: usize,
    mode: Mode,
    path: []const u8,
    first_visible_line: usize,
    screen_height: usize,

    const Self = @This();

    pub const Mode = enum {
        Normal,
        Insert,
    };

    pub fn init(
        allocator: Allocator,
        reader: AnyReader,
        font: *Font,
        font_size: usize,
        path: []const u8,
        screen_height: usize,
    ) !Self {
        var lines = ArrayList(ArrayListU8).init(allocator);
        var char_widths = ArrayList(ArrayList(usize)).init(allocator);
        while (true) {
            var line = ArrayListU8.init(allocator);
            reader.streamUntilDelimiter(line.writer().any(), '\n', null) catch |err| {
                if (err == error.EndOfStream) {
                    const utf8_string = Utf8String{ .data = line.items };
                    var utf8_iter = try utf8_string.iterate();
                    var glyph = utf8_iter.next();
                    var line_char_widths = ArrayList(usize).init(allocator);
                    while (glyph != null) : (glyph = utf8_iter.next()) {
                        const glyph_info = try font.get(glyph.?);
                        try line_char_widths.append(glyph_info.width);
                    }
                    if (line.items.len > 0 or lines.items.len == 0) {
                        // we've hit the end of stream after some characters, or we've got an empty file and need to insert one line to keep the cursor position meaningful
                        try lines.append(line);
                        try char_widths.append(line_char_widths);
                    }
                    return Self{
                        .data = lines,
                        .char_widths = char_widths,
                        .allocator = allocator,
                        .cursor_pos = .{ .x = 0, .y = 0 },
                        .target_x_position = 0,
                        .mode = .Normal,
                        .font = font,
                        .font_size = font_size,
                        .path = path,
                        .first_visible_line = 0,
                        .screen_height = screen_height,
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
    }

    pub fn flushUserEvents(self: *Self, p: *platform.Platform, redraw_needed: *bool) !bool {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                return false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                redraw_needed.* = true;
                p.handleWindowResized(self);
            } else if (event.type == c.SDL_TEXTINPUT) {
                redraw_needed.* = true;
                const code_point_byte_count = try unicode.utf8ByteSequenceLength(event.text.text[0]);
                const code_point = try unicode.utf8Decode(event.text.text[0..code_point_byte_count]);
                switch (self.mode) {
                    .Insert => try self.handleTextInputInsert(code_point),
                    .Normal => try self.handleTextInputNormal(code_point),
                }
            } else if (event.type == c.SDL_KEYDOWN) {
                redraw_needed.* = true;
                const running = switch (self.mode) {
                    .Insert => try self.handleKeyDownInsert(event.key.keysym.sym),
                    .Normal => self.handleKeyDownNormal(event.key.keysym.sym),
                };
                if (!running) return false;
            }
        }
        return true;
    }

    fn handleTextInputInsert(self: *Self, codePoint: Utf8String.CodePoint) !void {
        try self.insertCodePoint(codePoint);
    }

    fn handleTextInputNormal(self: *Self, codePoint: Utf8String.CodePoint) !void {
        switch (codePoint) {
            'i' => self.mode = .Insert,
            'a' => {
                self.mode = .Insert;
                self.handleMoveRight();
            },
            else => std.debug.print("Unhandled normal mode text input code point {}\n", .{codePoint}),
        }
    }

    fn handleKeyDownInsert(self: *Self, key: i32) !bool {
        switch (key) {
            c.SDLK_ESCAPE => self.switchToNormal(),
            c.SDLK_UP => self.handleMoveUp(),
            c.SDLK_DOWN => self.handleMoveDown(),
            c.SDLK_LEFT => self.handleMoveLeft(),
            c.SDLK_RIGHT => self.handleMoveRight(),
            c.SDLK_RETURN => try self.insertNewLine(),
            c.SDLK_BACKSPACE => try self.handleBackspace(),
            else => std.debug.print("Unhandled insert mode keypress char {}\n", .{key}),
        }
        return true;
    }

    fn handleKeyDownNormal(self: *Self, key: i32) bool {
        switch (key) {
            c.SDLK_ESCAPE => return false,
            c.SDLK_UP => self.handleMoveUp(),
            c.SDLK_DOWN => self.handleMoveDown(),
            c.SDLK_LEFT => self.handleMoveLeft(),
            c.SDLK_RIGHT => self.handleMoveRight(),
            else => std.debug.print("Unhandled insert mode keypress char {}\n", .{key}),
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

    pub fn insertNewLine(self: *Self) !void {
        var line_copy = try self.data.items[self.cursor_pos.y].clone();
        var char_widths_copy = try self.char_widths.items[self.cursor_pos.y].clone();

        self.data.items[self.cursor_pos.y].shrinkRetainingCapacity(self.cursor_pos.x);
        line_copy.replaceRangeAssumeCapacity(0, self.cursor_pos.x, &.{});

        self.char_widths.items[self.cursor_pos.y].shrinkRetainingCapacity(self.cursor_pos.x);
        char_widths_copy.replaceRangeAssumeCapacity(0, self.cursor_pos.x, &.{});

        self.cursor_pos.x = 0;
        self.cursor_pos.y += 1;
        try self.data.insert(self.cursor_pos.y, line_copy);
        try self.char_widths.insert(self.cursor_pos.y, char_widths_copy);
    }

    pub fn handleBackspace(self: *Self) !void {
        if (self.cursor_pos.x == 0) {
            if (self.cursor_pos.y == 0) {
                return;
            }
            const updated_x_pos = self.data.items[self.cursor_pos.y - 1].items.len;
            try self.data.items[self.cursor_pos.y - 1].appendSlice(self.data.items[self.cursor_pos.y].items);
            try self.char_widths.items[self.cursor_pos.y - 1].appendSlice(self.char_widths.items[self.cursor_pos.y].items);
            _ = self.data.orderedRemove(self.cursor_pos.y);
            _ = self.char_widths.orderedRemove(self.cursor_pos.y);
            self.cursor_pos = .{ .x = updated_x_pos, .y = self.cursor_pos.y - 1 };
        } else {
            _ = self.data.items[self.cursor_pos.y].orderedRemove(self.cursor_pos.x - 1);
            _ = self.char_widths.items[self.cursor_pos.y].orderedRemove(self.cursor_pos.x - 1);
            self.cursor_pos.x -= 1;
        }
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
        if (self.first_visible_line > self.cursor_pos.y) {
            self.first_visible_line -= 1;
        }
        self.setCursorToTargetX();
    }

    pub fn handleMoveDown(self: *Self) void {
        if (self.cursor_pos.y + 1 >= self.data.items.len) return;
        self.cursor_pos.y += 1;
        if (self.cursor_pos.y - self.first_visible_line >= self.visibleLines()) {
            self.first_visible_line += 1;
        }
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

    pub fn debugPrintText(self: *Self) void {
        for (self.data.items) |line| {
            std.debug.print("{s}\n", .{line.items});
        }
    }
    pub fn debugPrintCharWidths(self: *Self) void {
        for (self.char_widths.items) |widths| {
            std.debug.print("{any}\n", .{widths.items});
        }
    }

    pub fn debugPrint(self: *Self) void {
        std.debug.print("text: \n", .{});
        self.debugPrintText();
        std.debug.print("char_widths: \n", .{});
        self.debugPrintCharWidths();
        std.debug.print("cursor_pos: {}\n", .{self.cursor_pos});
        std.debug.print("target_x_pos: {}\n", .{self.target_x_position});
    }

    pub fn insertCodePoint(self: *Self, code_point: Utf8String.CodePoint) !void {
        const utf8_string = Utf8String{ .data = self.data.items[self.cursor_pos.y].items };
        const byte_count = try utf8_string.byteCountToIndex(self.cursor_pos.x);

        var buffer: [4]u8 = undefined;
        const code_point_byte_count = try unicode.utf8Encode(code_point, &buffer);

        for (0..code_point_byte_count) |i| {
            try self.data.items[self.cursor_pos.y].insert(byte_count + i, buffer[i]);
        }
        const added_char = try self.font.get(code_point);
        try self.char_widths.items[self.cursor_pos.y].insert(self.cursor_pos.x, added_char.width);

        self.cursor_pos.x += 1;
        self.target_x_position += added_char.width;
    }

    fn visibleLines(self: Self) usize {
        return self.screen_height / self.font.height;
    }
};
