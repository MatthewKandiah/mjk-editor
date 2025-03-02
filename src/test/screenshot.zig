const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("stb_image_write.h");
    @cInclude("SDL.h");
});
const platform = @import("../platform.zig");

// TODO-Matt: build test scenarios using SDL_PushEvent to simulate user actions
pub fn buildScenario() !platform.Platform {
    @panic("unimplemented\n");
}

pub fn writeScreenshot(allocator: Allocator, p: platform.Platform, screenshot_name: []const u8) !void {
    const out_data = try platformPixelDataToRGBA(allocator, p);
    defer allocator.free(out_data);
    const res = c.stbi_write_png(
        @ptrCast(screenshot_name),
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

pub fn checkScreenshot(allocator: Allocator, p: platform.Platform, screenshot_name: []const u8) !bool {
    const p_data = try platformPixelDataToRGBA(allocator, p);
    defer allocator.free(p_data);

    var screenshot_width: c_int = undefined;
    var screenshot_height: c_int = undefined;
    var screenshot_channel_count: c_int = undefined;
    const screenshot_data = c.stbi_load(
        @ptrCast(screenshot_name),
        &screenshot_width,
        &screenshot_height,
        &screenshot_channel_count,
        4,
    );
    if (screenshot_data == null) {
        @panic("stbi_load failed\n");
    }
    defer c.stbi_image_free(screenshot_data);

    const pixel_count: usize = @intCast(screenshot_width * screenshot_height);
    const expected_pixel_count: usize = @intCast(p.surface.w * p.surface.h);
    if (pixel_count != p.surface.w * p.surface.h) {
        p.printErr("Screenshot failed - expected pixel count: {}, actual pixel count: {}\n", .{ expected_pixel_count, pixel_count });
        return false;
    }

    for (0..pixel_count) |i| {
        if (screenshot_data[i] != p_data[i]) {
            return false;
        }
    }
    return true;
}

fn platformPixelDataToRGBA(allocator: Allocator, p: platform.Platform) ![]u8 {
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
    return out_data;
}
