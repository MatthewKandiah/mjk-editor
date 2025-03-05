const std = @import("std");
const screenshot = @import("./screenshot.zig");
const platform = @import("../platform.zig");
const Font = @import("../font.zig").Font;
const Colour = @import("../colour.zig").Colour;

pub fn main() void {
    std.debug.print("Generating screenshots...\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 16;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    const bg_colour = Colour{ .r = 64, .g = 64, .b = 64 };
    const fg_colour = Colour{ .r = 255, .g = 255, .b = 255 };

    var buffer = platform.readFile(allocator, "debug/test.txt", font, 16);
    const builder = screenshot.ScenarioBuilder.init(allocator).do(.right).doRepeated(.right, 5);
    const p = try screenshot.buildScenario(&buffer, builder, bg_colour, fg_colour);

    screenshot.writeScreenshot(allocator, p, "test_generate.png");
}
