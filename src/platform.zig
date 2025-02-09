const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});
const Buffer = @import("buffer.zig").Buffer;

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
