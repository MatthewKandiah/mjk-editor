const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});
const Buffer = @import("buffer.zig").Buffer;
const Font = @import("font.zig").Font;
const Position = @import("position.zig").Position;
const Colour = @import("colour.zig").Colour;
const Utf8String = @import("unicodeString.zig").Utf8String;

const std_err = std.io.getStdErr();
const std_out = std.io.getStdOut();

pub fn print(comptime fmt: []const u8, args: anytype) void {
    std_out.writer().print(fmt, args) catch {};
}

pub fn printErr(comptime fmt: []const u8, args: anytype) void {
    std_err.writer().print(fmt, args) catch {};
}

pub fn reportErr(comptime msg: []const u8, args: anytype) noreturn {
    printErr("ERROR: " ++ msg ++ "\n", args);
    crash();
}

pub const Platform = struct {
    window: ?*c.SDL_Window,
    surface: ?*c.SDL_Surface,

    const Self = @This();

    pub fn init() Self {
        const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS);
        if (sdl_init != 0) {
            reportErr("SDL_Init failed", .{});
        }

        const ttf_init = c.TTF_Init();
        if (ttf_init != 0) {
            reportErr("TTF_Init failed", .{});
        }

        return Self{
            .window = null,
            .surface = null,
        };
    }

    pub fn handleWindowResized(self: *Self, buffer: *Buffer) void {
        self.surface = c.SDL_GetWindowSurface(self.window.?);
        buffer.screen_height = @intCast(self.surface.?.h);
    }

    pub fn renderScreen(self: Self) void {
        const res = c.SDL_UpdateWindowSurface(self.window);
        if (res != 0) {
            reportErr("Failed to render screen", .{});
        }
    }

    pub fn clear(self: Self, colour: Colour) void {
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.?.pixels));
        const num_pixels: usize = @intCast(self.surface.?.w * self.surface.?.h);
        const sdl_colour = c.SDL_MapRGBA(self.surface.?.format, colour.r, colour.g, colour.b, c.SDL_ALPHA_OPAQUE);
        for (0..num_pixels) |i| {
            pixels[i] = sdl_colour;
        }
    }

    fn setPixelColour(self: Self, pos: Position, colour: Colour) void {
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.?.pixels));
        const surface_pitch: usize = @intCast(self.surface.?.w);
        const sdl_colour = c.SDL_MapRGBA(self.surface.?.format, colour.r, colour.g, colour.b, c.SDL_ALPHA_OPAQUE);
        pixels[pos.y * surface_pitch + pos.x] = sdl_colour;
    }

    fn getPixelColour(self: Self, pos: Position) Colour {
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.?.pixels));
        const surface_pitch: usize = @intCast(self.surface.?.w);
        var colour: Colour = undefined;
        const pixel = pixels[pos.y * surface_pitch + pos.x];
        var unnecessary: u8 = undefined;
        c.SDL_GetRGBA(pixel, self.surface.?.format, &colour.r, &colour.g, &colour.b, &unnecessary);
        return colour;
    }

    pub fn drawBuffer(self: Self, buffer: Buffer, bg_colour: Colour, fg_colour: Colour) !void {
        var y_offset: usize = 0;
        for (buffer.data.items, 0..) |line, line_num| {
            if (line_num < buffer.first_visible_line) continue;
            const utf8Data = Utf8String{ .data = line.items };
            const drawn_line_count = try self.drawUtf8String(
                utf8Data,
                buffer.font,
                .{ .x = 0, .y = y_offset },
                bg_colour,
                fg_colour,
                if (line_num == buffer.cursor_pos.y) buffer.cursor_pos.x else null,
                switch (buffer.mode) {
                    .Normal => .Block,
                    .Insert => .Line,
                },
                buffer.char_widths.items[line_num].items,
            );
            y_offset += buffer.font.height * drawn_line_count;
            if (y_offset + buffer.font.height >= buffer.screen_height) {
                return;
            }
        }
    }

    pub fn drawCharacter(self: Self, char: Utf8String.CodePoint, font: *Font, pos: Position, bg_colour: Colour, fg_colour: Colour) !usize {
        const glyph = try font.get(char);
        for (0..glyph.height) |j| {
            for (0..glyph.width) |i| {
                const surface_bytes_per_pixel: u8 = @intCast(self.surface.?.format.*.BytesPerPixel);
                std.debug.assert(surface_bytes_per_pixel == 4);
                const adjusted_pos = .{ .x = pos.x + i, .y = pos.y + j };
                self.setPixelColour(
                    adjusted_pos,
                    if (glyph.get(.{ .x = i, .y = j })) fg_colour else bg_colour,
                );
            }
        }
        return glyph.width;
    }

    pub fn drawUtf8String(
        self: Self,
        data: Utf8String,
        font: *Font,
        pos: Position,
        bg_colour: Colour,
        fg_colour: Colour,
        maybe_cursor_x: ?usize,
        cursor_draw_type: CursorDrawType,
        char_widths: []usize,
    ) !usize {
        var iter = try data.iterate();
        var current = iter.next();
        var x_index: usize = 0;
        var x_offset: usize = 0;
        const screen_width: usize = @intCast(self.surface.?.w);
        var line_count: usize = 0;
        var draw_pos: Position = pos;
        while (current) |char| {
            const next_char_width = char_widths[x_index];
            if (pos.x + x_offset + next_char_width >= screen_width) {
                line_count += 1;
                x_offset = 0;
                draw_pos = .{ .x = pos.x, .y = pos.y + font.height * line_count };
            }
            const drawn_char_width = try self.drawCharacter(char, font, draw_pos, bg_colour, fg_colour);
            if (next_char_width != drawn_char_width) {
                reportErr("drawn character width did not match buffer data", .{});
            }
            if (maybe_cursor_x == x_index) {
                try self.drawCursor(draw_pos, drawn_char_width, font.height, bg_colour, fg_colour, cursor_draw_type);
            }

            x_offset += drawn_char_width;
            x_index += 1;
            current = iter.next();
            draw_pos = .{ .x = pos.x + x_offset, .y = pos.y + font.height * line_count };
        }

        if (maybe_cursor_x) |cursor_x| {
            if (cursor_x >= x_index) {
                try self.drawSimpleBlock(
                    draw_pos,
                    font.height / 2,
                    font.height,
                    fg_colour,
                );
            }
        }
        return line_count + 1;
    }

    pub fn drawCursor(self: Self, pos: Position, width: usize, height: usize, bg_colour: Colour, fg_colour: Colour, cursor_draw_type: CursorDrawType) !void {
        switch (cursor_draw_type) {
            .Block => {
                try self.drawBlockCursor(pos, width, height, bg_colour, fg_colour);
            },
            .Line => {
                try self.drawLineCursor(pos, height, fg_colour);
            },
        }
    }

    fn drawBlockCursor(self: Self, pos: Position, width: usize, height: usize, bg_colour: Colour, fg_colour: Colour) !void {
        for (0..height) |j| {
            for (0..width) |i| {
                const surface_bytes_per_pixel: u8 = @intCast(self.surface.?.format.*.BytesPerPixel);
                std.debug.assert(surface_bytes_per_pixel == 4);
                const adjusted_pos = .{ .x = pos.x + i, .y = pos.y + j };
                const current_colour = self.getPixelColour(adjusted_pos);
                const isBackground = current_colour.equals(bg_colour);
                self.setPixelColour(
                    adjusted_pos,
                    if (isBackground) fg_colour else bg_colour,
                );
            }
        }
    }

    fn drawLineCursor(self: Self, pos: Position, height: usize, colour: Colour) !void {
        const cursor_width = 4;
        try self.drawSimpleBlock(pos, cursor_width, height, colour);
    }

    pub fn drawSimpleBlock(self: Self, pos: Position, width: usize, height: usize, colour: Colour) !void {
        const surface_bytes_per_pixel: u8 = @intCast(self.surface.?.format.*.BytesPerPixel);
        for (0..height) |j| {
            for (0..width) |i| {
                std.debug.assert(surface_bytes_per_pixel == 4);
                const adjusted_pos = .{ .x = pos.x + i, .y = pos.y + j };
                self.setPixelColour(
                    adjusted_pos,
                    colour,
                );
            }
        }
    }
};

pub fn crash() noreturn {
    std.process.exit(1);
}

pub fn readFile(allocator: Allocator, path: []const u8, font: *Font, font_size: usize, screen_height: usize) !Buffer {
    const cwd = std.fs.cwd();
    if (cwd.openFile(path, std.fs.File.OpenFlags{ .mode = .read_only })) |file| {
        defer file.close();
        return Buffer.init(allocator, file.reader().any(), font, font_size, path, screen_height);
    } else |err| switch (err) {
        error.FileNotFound => {
            var buf: [0]u8 = .{};
            var fbs = std.io.fixedBufferStream(&buf);
            const reader = fbs.reader().any();
            return Buffer.init(allocator, reader, font, font_size, path, screen_height);
        },
        else => std.debug.panic("Unexpected error reading file\n", .{}),
    }
}

pub fn writeBuffer(buffer: Buffer) !void {
    const cwd = std.fs.cwd();
    const file = cwd.openFile(buffer.path, std.fs.File.OpenFlags{ .mode = .write_only }) catch try cwd.createFile(buffer.path, .{});
    defer file.close();

    try buffer.write(file.writer().any());
}

const CursorDrawType = enum {
    Line,
    Block,
};
