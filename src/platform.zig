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

    pub fn drawCharacter(self: Self, char: Utf8String.CodePoint, font: Font, pos: Position, bg_colour: Colour, fg_colour: Colour) !void {
        const glyph = try font.get(char);
        const pixels: [*]u32 = @alignCast(@ptrCast(self.surface.pixels));
        // TODO-Matt: Could we define a GlyphInfo iterator that gives you each row of bits []bool in order?
        // might make this neater?
        for (0..glyph.height) |j| {
            for (0..glyph.width) |i| {
                const surface_pitch: usize = @intCast(self.surface.w);
                const surface_bytes_per_pixel: u8 = @intCast(self.surface.format.*.BytesPerPixel);
                std.debug.assert(surface_bytes_per_pixel == 4);
                const base_index: usize = surface_bytes_per_pixel * (pos.x + pos.y * surface_pitch);
                const index = base_index + j * surface_pitch + i;
                const sdl_fg_colour = c.SDL_MapRGBA(
                    self.surface.format,
                    fg_colour.r,
                    fg_colour.g,
                    fg_colour.b,
                    c.SDL_ALPHA_OPAQUE,
                );
                const sdl_bg_colour = c.SDL_MapRGBA(
                    self.surface.format,
                    bg_colour.r,
                    bg_colour.g,
                    bg_colour.b,
                    c.SDL_ALPHA_OPAQUE,
                );
                pixels[index] = if (glyph.data[j * glyph.width + i]) sdl_fg_colour else sdl_bg_colour;
            }
        }
    }
};

pub fn crash() noreturn {
    std.process.exit(1);
}

pub fn readFile(allocator: Allocator, path: []const u8) !Buffer {
    const file = try std.fs.cwd().openFile(path, std.fs.File.OpenFlags{ .mode = .read_only });
    defer file.close();

    const buffer = try Buffer.init(allocator, file.reader().any());
    return buffer;
}

pub fn writeFile(path: []const u8, buffer: Buffer) !void {
    // TODO-Matt: Create file if it doesn't exist
    const file = try std.fs.cwd().openFile(path, std.fs.File.OpenFlags{ .mode = .write_only });
    defer file.close();

    try buffer.write(file.writer().any());
}
