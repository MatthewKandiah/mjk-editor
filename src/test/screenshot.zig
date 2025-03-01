const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("stb_image_write.h");
    @cInclude("SDL.h");
});
const platform = @import("../platform.zig");

pub fn writeScreenshot(allocator: Allocator, p: platform.Platform) !void {
    const pixels: [*]u32 = @alignCast(@ptrCast(p.surface.pixels));
    const pixel_count: usize = @intCast(p.surface.w * p.surface.h);
    var out_data = try allocator.alloc(u8, 4 * pixel_count);
    for (pixels, 0..pixel_count) |pixel, i| {
        var r: u8 = undefined;
        var g: u8 = undefined;
        var b: u8 = undefined;
        var a: u8 = undefined;
        c.SDL_GetRGBA(pixel, @ptrCast(p.surface.format), &r, &g, &b, &a);
        out_data[4 * i + 0] = r;
        out_data[4 * i + 1] = g;
        out_data[4 * i + 2] = b;
        out_data[4 * i + 3] = a;
    }
    const res = c.stbi_write_png(
        "test_screenshot.png",
        p.surface.w,
        p.surface.h,
        4,
        @ptrCast(out_data),
        4 * p.surface.w,
    );
    if (res != 1) {
        @panic("stbi_write_png failed\n");
    }
}
