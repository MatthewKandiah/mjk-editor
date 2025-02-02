const std = @import("std");
const lib = @import("./lib.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

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

pub fn main() !void {
    const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS);
    assert(sdl_init == 0, "ERROR - SDL_Init failed: {}", .{sdl_init});

    const ttf_init = c.TTF_Init();
    assert(ttf_init == 0, "ERROR - TTF_Init failed: {}", .{ttf_init});

    const jetbrains_mono_font = c.TTF_OpenFont("./font/jetbrains-mono/JetBrainsMono-Regular.ttf", 24) orelse fatal("ERROR - Loading JetBrainsMono font failed", .{});
    defer c.TTF_CloseFont(jetbrains_mono_font);

    const colour = c.SDL_Color{ .r = 0, .g = 255, .b = 0, .a = 0 };
    const text_surface = c.TTF_RenderText_Solid(jetbrains_mono_font, "Hello TTF", colour);

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
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => running = false,
                    else => std.debug.print("unhandled key down event\n", .{}),
                }
            }
        }

        const src_rect = text_surface.*.clip_rect;
        var dst_rect = c.SDL_Rect{
            .x = @divTrunc(window_surface.*.w, 2) - @divTrunc(text_surface.*.w, 2),
            .y = @divTrunc(window_surface.*.h, 2) - @divTrunc(text_surface.*.h, 2),
            .w = src_rect.w,
            .h = src_rect.h,
        };
        const blit_res = c.SDL_BlitSurface(
            text_surface,
            @ptrCast(&src_rect),
            window_surface,
            @ptrCast(&dst_rect),
        );
        assert(blit_res == 0, "ERROR - SDL_BlibSurface failed: {}", .{blit_res});

        const update_res = c.SDL_UpdateWindowSurface(window);
        assert(update_res == 0, "ERROR - SDL_UpdateWindowSurface failed: {}", .{update_res});
    }
}
