const std = @import("std");
const screenshot = @import("./test/screenshot.zig");
const platform = @import("./platform.zig");
const Font = @import("./font.zig").Font;
const Colour = @import("./colour.zig").Colour;
const c = @cImport({
    @cInclude("SDL2/SDL_ttf.h");
});

pub fn main() !void {
    std.debug.print("Generating screenshots...\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (c.TTF_Init() < 0) {
        @panic("ERROR - SDL TTF initialisation failed");
    }
    const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 16;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    const bg_colour = Colour{ .r = 64, .g = 64, .b = 64 };
    const fg_colour = Colour{ .r = 255, .g = 255, .b = 255 };

    var buffer = try platform.readFile(allocator, "debug/test.txt", &font, font_size);
    const builder = screenshot.ScenarioBuilder.init(allocator)
        .do(.right)
        .do(.right);

    const p = try screenshot.buildScenario(allocator, &buffer, builder, bg_colour, fg_colour);

    try screenshot.writeScreenshot(allocator, p, "test_generate.png");
}
