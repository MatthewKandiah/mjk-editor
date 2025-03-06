const std = @import("std");
const screenshot = @import("./test/screenshot.zig");
const platform = @import("./platform.zig");
const Font = @import("./font.zig").Font;
const Colour = @import("./colour.zig").Colour;
const c = @cImport({
    @cInclude("SDL2/SDL_ttf.h");
});

// TODO-Matt: command line argument to toggle check/generate instead of separate executables

pub fn main() !void {
    std.debug.print("Generating screenshots...\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (c.TTF_Init() < 0) {
        @panic("ERROR - SDL TTF initialisation failed");
    }

    const builder1 =
        screenshot.ScenarioBuilder
        .init(allocator)
        .do(.right)
        .do(.right)
        .do(.left);

    const builder2 =
        screenshot.ScenarioBuilder
        .init(allocator)
        .do(.right)
        .do(.right)
        .do(.right);

    var generate_count: usize = 0;

    generate_count += if (try screenshot.screenshotTest(
        allocator,
        "debug/test.txt",
        "test_generate.png",
        builder1,
        true,
    )) 1 else 0;

    generate_count += if (try screenshot.screenshotTest(
        allocator,
        "debug/test.txt",
        "test_generate_2.png",
        builder2,
        true,
    )) 1 else 0;

    var pass_count: usize = 0;
    var fail_count: usize = 0;
    var res: bool = undefined;

    // pass
    res = try screenshot.screenshotTest(
        allocator,
        "debug/test.txt",
        "test_generate.png",
        builder1,
        false,
    );
    if (res) {
        pass_count += 1;
    } else {
        fail_count += 1;
    }

    // pass
    res = try screenshot.screenshotTest(
        allocator,
        "debug/test.txt",
        "test_generate_2.png",
        builder2,
        false,
    );
    if (res) {
        pass_count += 1;
    } else {
        fail_count += 1;
    }

    // fail
    res = try screenshot.screenshotTest(
        allocator,
        "debug/test.txt",
        "test_generate.png",
        builder2,
        false,
    );
    if (res) {
        pass_count += 1;
    } else {
        fail_count += 1;
    }

    std.debug.print("generate_count: {}\n", .{generate_count});
    std.debug.print("pass_count: {}\n", .{pass_count});
    std.debug.print("fail_count: {}\n", .{fail_count});
}
