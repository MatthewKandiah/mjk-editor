const std = @import("std");
const pf = @import("platform.zig");
const Platform = pf.Platform;
const Font = @import("font.zig").Font;
const Utf8String = @import("unicodeString.zig").Utf8String;
const Colour = @import("colour.zig").Colour;
const Position = @import("position.zig").Position;
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
    var buffer = try pf.readFile(allocator, in_filepath);

    const font_filepath = "font/ubuntu-mono/ubuntu_mono.ttf";
    // const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 36;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    const bg_colour = Colour{ .r = 255, .g = 255, .b = 0 };
    const fg_colour = Colour{ .r = 0, .g = 0, .b = 255 };

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        // TODO-Matt: pull out a draw buffer function
        var y_offset: usize = 0;
        for (buffer.data.items) |line| {
            const utf8Data = Utf8String{ .data = line.items };
            try platform.drawUtf8String(
                utf8Data,
                &font,
                .{ .x = 0, .y = y_offset },
                bg_colour,
                fg_colour,
            );
            y_offset += font.height;
        }
        // draw cursor
        // TODO-Matt: requires converting the buffer.cursor_pos to a pixel pos (which depends on the buffer contents and font character widths) and the next character's dimensions
        // try platform.drawCursor(
        //     cursor_pixel_pos,
        //     cursor_char_width,
        //     cursor_char_height,
        // );
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                running = false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                platform.handleWindowResized();
            } else if (event.type == c.SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => running = false,
                    // TODO-Matt: super rough and messy, need to think about how we'll handle cursor movement in finite-length lines
                    c.SDLK_UP => buffer.cursor_pos.y -= 1,
                    c.SDLK_DOWN => buffer.cursor_pos.y += 1,
                    c.SDLK_LEFT => buffer.cursor_pos.x -= 1,
                    c.SDLK_RIGHT => buffer.cursor_pos.x += 1,
                    else => platform.print("Unhandled keypress\n", .{}),
                }
            }
        }
        platform.renderScreen();
    }

    try pf.writeFile(out_filepath, buffer);
}
