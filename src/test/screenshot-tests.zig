const std = @import("std");
const mjk = @import("mjk");
const screenshot = @import("./screenshot.zig");
const ScenarioBuilder = screenshot.ScenarioBuilder;
const platform = mjk.platform;
const Font = mjk.font.Font;
const Colour = mjk.colour.Colour;
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("SDL2/SDL_ttf.h");
});

const inputs_dir_path = "src/test/resources/inputs/";
const outputs_dir_path = "src/test/resources/outputs/";

var success_count: usize = 0;
var total_count: usize = 0;
var generate: bool = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len > 2) {
        std.debug.print("USAGE: Call with no arguments to check screenshots, call with argument `gen` to generate screenshots\n", .{});
        platform.crash();
    }
    generate = if (args.len == 2 and std.mem.eql(u8, args[1], "gen")) true else false;

    if (generate) {
        std.debug.print("Generating screenshots...\n", .{});
    } else {
        std.debug.print("Checking screenshots...\n", .{});
    }
    if (c.TTF_Init() < 0) {
        @panic("ERROR - SDL TTF initialisation failed");
    }

    try runTest(
        allocator,
        "hello-world.txt",
        "hello-world-no-action.png",
        ScenarioBuilder.init(allocator),
    );

    try runTest(
        allocator,
        "hello-world.txt",
        "hello-world-move-right.png",
        ScenarioBuilder.init(allocator).do(.right),
    );

    try runTest(
        allocator,
        "hello-world.txt",
        "hello-world-move-right-then-left.png",
        ScenarioBuilder.init(allocator).doRepeated(.right, 5).doRepeated(.left, 3),
    );

    try runTest(
        allocator,
        "hello-world-repeated.txt",
        "hello-world-move-down.png",
        ScenarioBuilder.init(allocator).doRepeated(.down, 4),
    );

    try runTest(
        allocator,
        "hello-world-repeated.txt",
        "hello-world-move-down-then-up.png",
        ScenarioBuilder.init(allocator)
            .doRepeated(.down, 6)
            .doRepeated(.up, 4),
    );

    try runTest(
        allocator,
        "hello-world.txt",
        "hello-world-insert.png",
        ScenarioBuilder.init(allocator)
            .do(.i),
    );

    try runTest(
        allocator,
        "hello-world.txt",
        "hello-world-insert-end-line.png",
        ScenarioBuilder.init(allocator)
            .do(.i)
            .doRepeated(.right, 100),
    );

    reportResults();
}

fn runTest(allocator: Allocator, comptime input_name: []const u8, comptime output_name: []const u8, builder: *ScenarioBuilder) !void {
    total_count += 1;
    const result = screenshot.screenshotTest(
        allocator,
        inputs_dir_path ++ input_name,
        outputs_dir_path ++ output_name,
        builder,
        generate,
    ) catch false;
    success_count += if (result) 1 else 0;
    if (!result) {
        std.debug.print("Test failed\n\tinput_name: {s}\n\toutput_name: {s}\n", .{ input_name, output_name });
    }
}

fn reportResults() void {
    if (generate) {
        std.debug.print("Wrote {} out of {} screenshots\n", .{ success_count, total_count });
    } else {
        std.debug.print("Passed {} out of {} screenshots\n", .{ success_count, total_count });
    }
}
