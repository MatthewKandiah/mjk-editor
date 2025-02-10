const std = @import("std");
const pf = @import("platform.zig");
const Platform = pf.Platform;
const Font = @import("font.zig").Font;
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub fn main() !void {
    var platform = Platform.init();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const in_filepath = "debug/test.txt";
    const out_filepath = "debug/test.out.txt";
    const buffer = try pf.readFile(allocator, in_filepath);

    const font_filepath = "font/ubuntu-mono/ubuntu_mono.ttf";
    const font_size = 24;
    const font = try Font.init(allocator, font_filepath, font_size);

    const char_a = font.table.get('a') orelse std.debug.panic("blew up\n", .{});
    for (0..char_a.height) |j| {
        for (0..char_a.width) |i| {
            const index = j * char_a.width + i;
            if (char_a.data[index]) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                running = false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                platform.handleWindowResized();
            } else if (event.type == c.SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => running = false,
                    else => platform.print("Unhandled keypress\n", .{}),
                }
            }
        }
        platform.renderScreen();
    }

    try pf.writeFile(out_filepath, buffer);
}
