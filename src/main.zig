const std = @import("std");
const mjk = @import("mjk");
const pf = mjk.platform;
const Platform = pf.Platform;
const Font = mjk.font.Font;
const Utf8String = mjk.unicodeString.Utf8String;
const Colour = mjk.colour.Colour;
const Position = mjk.position.Position;
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

    platform.window = @ptrCast(window);
    platform.surface = @ptrCast(surface);

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

    var running = true;
    while (running) {
        platform.clear(bg_colour);

        running = buffer.flushUserEvents(&platform);
        try platform.drawBuffer(buffer, bg_colour, fg_colour);
        platform.renderScreen();
    }

    try pf.writeFile(out_filepath, buffer);
}
