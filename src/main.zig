const std = @import("std");
const pf = @import("platform.zig");
const Platform = pf.Platform;
const Font = @import("font.zig").Font;
const Utf8String = @import("unicodeString.zig").Utf8String;
const Colour = @import("colour.zig").Colour;
const Position = @import("position.zig").Position;
const screenshot = @import("test/screenshot.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

// TODO-Matt: memory use and cpu use profiling
pub fn main() !void {
    var platform = Platform.init();

    const window = c.SDL_CreateWindow(
        "mjk",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        platform.printErr("ERROR - Failed to create window\n", .{});
        pf.crash();
    };

    const surface = c.SDL_GetWindowSurface(window) orelse {
        platform.printErr("ERROR - Failed to get window surface\n", .{});
        pf.crash();
    };

    platform.window = window;
    platform.surface = surface;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // const font_filepath = "font/ubuntu-mono/ubuntu_mono.ttf";
    const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 36;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    const in_filepath = "debug/test.txt";
    const out_filepath = "debug/test.out.txt";
    var buffer = try pf.readFile(allocator, in_filepath, &font, font_size);

    const bg_colour = Colour{ .r = 64, .g = 64, .b = 64 };
    const fg_colour = Colour{ .r = 255, .g = 255, .b = 255 };

    var event: c.SDL_Event = undefined;
    var running = true;
    while (running) {
        platform.clear(bg_colour);

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

        const cursor_line = Utf8String{ .data = buffer.data.items[buffer.cursor_pos.y].items };
        const cursor_pixel_pos = Position{ .x = try (cursor_line.width(&font, 0, buffer.cursor_pos.x)), .y = buffer.cursor_pos.y * font.height };
        if (buffer.cursor_pos.x >= buffer.data.items[buffer.cursor_pos.y].items.len) {
            const cursor_width = @divTrunc(font_size, 2);
            try platform.drawSimpleBlock(cursor_pixel_pos, cursor_width, font.height, fg_colour);
        } else {
            const cursor_char_width = (try cursor_line.getGlyph(&font, buffer.cursor_pos.x)).width;
            try platform.drawCursor(
                cursor_pixel_pos,
                cursor_char_width,
                font.height,
                bg_colour,
                fg_colour,
                buffer.mode,
            );
        }

        // TODO-Matt: pull out flush user events function
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                running = false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                platform.handleWindowResized();
            } else if (event.type == c.SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => running = false,
                    c.SDLK_UP => buffer.handleMoveUp(),
                    c.SDLK_DOWN => buffer.handleMoveDown(),
                    c.SDLK_LEFT => buffer.handleMoveLeft(),
                    c.SDLK_RIGHT => buffer.handleMoveRight(),
                    c.SDLK_i => buffer.mode = .Insert,
                    c.SDLK_n => buffer.switchToNormal(),
                    else => platform.print("Unhandled keypress\n", .{}),
                }
            }
        }

        platform.renderScreen();
    }

    try pf.writeFile(out_filepath, buffer);
}
