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

const bg_colour = Colour{ .r = 64, .g = 64, .b = 64 };
const fg_colour = Colour{ .r = 255, .g = 255, .b = 255 };

// TODO-Matt: memory use and cpu use profiling
// TODO-Matt: add line numbers
// TODO-Matt: support more normal mode navigation options
// TODO-Matt: support command mode
// TODO-Matt: support multiple open buffers
// TODO-Matt: keyword highlighting - based on file extension, set fg and bg colour for keywords
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
        pf.reportErr("Failed to create window", .{});
    };

    const surface = c.SDL_GetWindowSurface(window) orelse {
        pf.reportErr("Failed to get window surface", .{});
    };

    platform.window = @ptrCast(window);
    platform.surface = @ptrCast(surface);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // TODO-Matt: embed fonts into executable
    // const font_filepath = "font/ubuntu-mono/ubuntu_mono.ttf";
    const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 36;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    var arg_iter = try std.process.argsWithAllocator(allocator);
    defer arg_iter.deinit();
    _ = arg_iter.skip();
    const filepath = arg_iter.next() orelse std.debug.panic("Missing first argument\n", .{});

    var buffer = try pf.readFile(allocator, filepath, &font, font_size, @intCast(platform.surface.?.h));

    var running = true;
    var redraw_needed = true;
    while (running) {
        running = try buffer.flushUserEvents(&platform, &redraw_needed);
        if (redraw_needed) {
            platform.clear(bg_colour);
            try platform.drawBuffer(buffer, bg_colour, fg_colour);
            platform.renderScreen();
            redraw_needed = false;
        }
    }

    try pf.writeBuffer(buffer);
}
