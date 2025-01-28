const std = @import("std");
const lib = @import("./lib.zig");
const c = @cImport(
    @cInclude("SDL2/SDL.h"),
);

pub fn main() !void {
    const a = 1;
    const b = 2;
    const d = lib.add(a, b);
    std.debug.print("{} + {} = {}\n", .{ a, b, d });

    const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS);
    std.debug.assert(sdl_init == 0);

    const window = c.SDL_CreateWindow(
        "mjk-editor",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse std.debug.panic("Failed to create window", .{});

    _ = window;
    while (true) {}
}
