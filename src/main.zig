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
    var buffer = try pf.readFile(allocator, in_filepath);

    const font_filepath = "font/ubuntu-mono/ubuntu_mono.ttf";
    // const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 36;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        var y_offset: usize = 0;
        for (buffer.data.items, 0..) |line, y_pos| {
            const utf8Data = Utf8String{ .data = line.items };
            try platform.drawUtf8String(
                utf8Data,
                &font,
                .{ .x = 16, .y = y_offset },
                .{ .r = 255, .g = 255, .b = 0 },
                .{ .r = 0, .g = 0, .b = 255 },
                // TODO-Matt: Swapping colours is an easy way to show the cursor in normal mode, what are we going to do for insertion mode?
                if (y_pos == buffer.cursor_pos.y) buffer.cursor_pos.x else null,
            );
            y_offset += font.height;
        }
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
