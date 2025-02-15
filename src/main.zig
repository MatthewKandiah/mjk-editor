const std = @import("std");
const pf = @import("platform.zig");
const Platform = pf.Platform;
const Font = @import("font.zig").Font;
const Utf8String = @import("unicodeString.zig").Utf8String;
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
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        _ = try platform.drawCharacter(0x5B, &font, .{ .x = 48, .y = 64 }, .{ .r = 122, .g = 122, .b = 122 }, .{ .r = 255, .g = 0, .b = 0 });
        _ = try platform.drawCharacter(0x58, &font, .{ .x = 32, .y = 92 }, .{ .r = 122, .g = 122, .b = 122 }, .{ .r = 255, .g = 255, .b = 0 });
        // draw something that doesn't exist in the first block of characters
        _ = try platform.drawCharacter('±', &font, .{ .x = 16, .y = 32 }, .{ .r = 122, .g = 122, .b = 122 }, .{ .r = 255, .g = 255, .b = 255 });
        var input = [_]u8{'H', 'e', 'l', 'l', 'o', ' ', 'W', 'o', 'r', 'l', 'd'};
        const utf8Data = Utf8String{ .data = &input};
        try platform.drawUtf8String(utf8Data, &font, .{ .x = 0, .y = 0 }, .{ .r = 255, .g = 255, .b = 255 }, .{ .r = 0, .g = 0, .b = 0 });
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
