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

pub const Platform = struct {
    window: *c.SDL_Window,
    surface: *c.SDL_Surface,
    stdout: std.fs.File,
    stderr: std.fs.File,

    const Self = @This();

    pub fn init() Self {
        const stderr = std.io.getStdErr();
        const stdout = std.io.getStdOut();

        const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS);
        if (sdl_init != 0) {
            _ = stderr.write("ERROR - SDL_Init failed\n") catch {};
            crash();
        }

        const ttf_init = c.TTF_Init();
        if (ttf_init != 0) {
            _ = stderr.write("ERROR - TTF_Init failed\n") catch {};
            crash();
        }

        const window = c.SDL_CreateWindow(
            "mjk",
            c.SDL_WINDOWPOS_UNDEFINED,
            c.SDL_WINDOWPOS_UNDEFINED,
            800,
            600,
            c.SDL_WINDOW_RESIZABLE,
        ) orelse {
            _ = stderr.write("ERROR - Failed to create window") catch {};
            crash();
        };

        const surface = c.SDL_GetWindowSurface(window) orelse {
            _ = stderr.write("ERROR - Failed to get window surface") catch {};
            crash();
        };
        return Self{
            .window = window,
            .surface = surface,
            .stdout = stdout,
            .stderr = stderr,
        };
    }

    pub fn handleWindowResized(self: *Self) void {
        self.surface = c.SDL_GetWindowSurface(self.window);
    }

    pub fn print(self: Self, comptime fmt: []const u8, args: anytype) void {
        self.stdout.writer().print(fmt, args) catch {};
    }

    pub fn printErr(self: Self, comptime fmt: []const u8, args: anytype) void {
        self.stderr.writer().print(fmt, args) catch {};
    }

    pub fn renderScreen(self: Self) void {
        const res = c.SDL_UpdateWindowSurface(self.window);
        if (res != 0) {
            self.printErr("ERROR - Failed to render screen\n", .{});
            crash();
        }
    }

    pub fn clear(self: Self, colour: Colour) void {
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.pixels));
        const num_pixels: usize = @intCast(self.surface.w * self.surface.h);
        const sdl_colour = c.SDL_MapRGBA(self.surface.format, colour.r, colour.g, colour.b, c.SDL_ALPHA_OPAQUE);
        for (0..num_pixels) |i| {
            pixels[i] = sdl_colour;
        }
    }

    fn setPixelColour(self: Self, pos: Position, colour: Colour) void {
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.pixels));
        const surface_pitch: usize = @intCast(self.surface.w);
        const sdl_colour = c.SDL_MapRGBA(self.surface.format, colour.r, colour.g, colour.b, c.SDL_ALPHA_OPAQUE);
        pixels[pos.y * surface_pitch + pos.x] = sdl_colour;
    }

    fn getPixelColour(self: Self, pos: Position) Colour {
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.pixels));
        const surface_pitch: usize = @intCast(self.surface.w);
        var colour: Colour = undefined;
        const pixel = pixels[pos.y * surface_pitch + pos.x];
        var unnecessary: u8 = undefined;
        c.SDL_GetRGBA(pixel, self.surface.format, &colour.r, &colour.g, &colour.b, &unnecessary);
        return colour;
    }

    pub fn drawCharacter(self: Self, char: Utf8String.CodePoint, font: *Font, pos: Position, bg_colour: Colour, fg_colour: Colour) !usize {
        const glyph = try font.get(char);
        for (0..glyph.height) |j| {
            for (0..glyph.width) |i| {
                const surface_bytes_per_pixel: u8 = @intCast(self.surface.format.*.BytesPerPixel);
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

    // TODO-Matt: also draw a space at the empty position at the end of the line (also handles navigating to empty lines)
    pub fn drawUtf8String(self: Self, data: Utf8String, font: *Font, pos: Position, bg_colour: Colour, fg_colour: Colour) !void {
        var iter = try data.iterate();
        var current = iter.next();
        var x_offset: usize = 0;
        while (current) |char| : (current = iter.next()) {
            const draw_pos = Position{ .x = pos.x + x_offset, .y = pos.y };
            const drawn_width = try self.drawCharacter(char, font, draw_pos, bg_colour, fg_colour);
            x_offset += drawn_width;
        }
    }

    pub fn drawCursor(self: Self, pos: Position, width: usize, height: usize, bg_colour: Colour, fg_colour: Colour, mode: Buffer.Mode) !void {
        switch (mode) {
            .Normal => {
                try self.drawBlockCursor(pos, width, height, bg_colour, fg_colour);
            },
            .Insert => {
                try self.drawLineCursor(pos, height, fg_colour);
            },
        }
    }

    fn drawBlockCursor(self: Self, pos: Position, width: usize, height: usize, bg_colour: Colour, fg_colour: Colour) !void {
        for (0..height) |j| {
            for (0..width) |i| {
                const surface_bytes_per_pixel: u8 = @intCast(self.surface.format.*.BytesPerPixel);
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
        for (0..height) |j| {
            for (0..width) |i| {
                const surface_bytes_per_pixel: u8 = @intCast(self.surface.format.*.BytesPerPixel);
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

pub fn readFile(allocator: Allocator, path: []const u8, font: *Font, font_size: usize) !Buffer {
    const file = try std.fs.cwd().openFile(path, std.fs.File.OpenFlags{ .mode = .read_only });
    defer file.close();

    return Buffer.init(allocator, file.reader().any(), font, font_size);
}

pub fn writeFile(path: []const u8, buffer: Buffer) !void {
    // TODO-Matt: Create file if it doesn't exist
    const file = try std.fs.cwd().openFile(path, std.fs.File.OpenFlags{ .mode = .write_only });
    defer file.close();

    try buffer.write(file.writer().any());
}
