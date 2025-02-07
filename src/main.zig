const std = @import("std");
const lib = @import("./lib.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub fn main() !void {
    const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS);
    assert(sdl_init == 0, "ERROR - SDL_Init failed: {}", .{sdl_init});

    const ttf_init = c.TTF_Init();
    assert(ttf_init == 0, "ERROR - TTF_Init failed: {}", .{ttf_init});

    const window = c.SDL_CreateWindow(
        "mjk",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse fatal("ERROR - SDL_CreateWindow failed", .{});
    var window_surface = c.SDL_GetWindowSurface(window);

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                running = false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                window_surface = c.SDL_GetWindowSurface(window);
            } else if (event.type == c.SDL_KEYDOWN) {
                std.debug.print("unhandled key down event\n", .{});
            }
        }

        const update_res = c.SDL_UpdateWindowSurface(window);
        assert(update_res == 0, "ERROR - SDL_UpdateWindowSurface failed: {}", .{update_res});
    }
}

pub fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt, args);
    std.debug.print("\n", .{});
    std.process.exit(1);
}

pub fn assert(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        fatal(fmt, args);
    }
}

