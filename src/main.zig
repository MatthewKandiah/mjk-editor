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

    // const font_filepath = "font/ubuntu-mono/ubuntu_mono.ttf";
    const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 32;
    const font = try Font.init(allocator, font_filepath, font_size);

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        platform.drawCharacter('a', font, .{ .x = 48, .y = 64 }, .{ .r = 122, .g = 122, .b = 122 }, .{ .r = 255, .g = 0, .b = 0 });
        platform.drawCharacter('b', font, .{ .x = 32, .y = 92 }, .{ .r = 122, .g = 122, .b = 122 }, .{ .r = 255, .g = 255, .b = 0 });
        platform.drawCharacter('c', font, .{ .x = 16, .y = 32 }, .{ .r = 122, .g = 122, .b = 122 }, .{ .r = 255, .g = 255, .b = 255 });
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
