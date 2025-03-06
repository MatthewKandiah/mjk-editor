const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("stb_image_write.h");
    @cInclude("SDL.h");
});
const Font = @import("../font.zig").Font;
const platform = @import("../platform.zig");
const Buffer = @import("../buffer.zig").Buffer;
const Colour = @import("../colour.zig").Colour;

fn sdlKeyDownEvent(sym: c_int) c.SDL_Event {
    return c.SDL_Event{ .key = .{ .type = c.SDL_KEYDOWN, .keysym = .{ .sym = sym } } };
}

pub const UserEvent = enum {
    right,

    const Self = @This();

    pub fn toSDLEvent(self: Self) c.SDL_Event {
        return switch (self) {
            .right => sdlKeyDownEvent(c.SDLK_RIGHT),
        };
    }
};

pub const ScenarioBuilder = struct {
    user_events: std.ArrayList(UserEvent),

    const Self = @This();

    pub fn init(allocator: Allocator) *Self {
        var result = allocator.create(Self) catch @panic("ERROR - failed to allocate builder");
        result.user_events = std.ArrayList(UserEvent).init(allocator);
        return result;
    }

    pub fn do(self: *Self, event: UserEvent) *Self {
        self.user_events.append(event) catch @panic("ERROR - failed to append event to scenario");
        return self;
    }

    pub fn fireEvents(self: Self, allocator: Allocator) !void {
        var buf = try allocator.alloc(c.SDL_Event, self.user_events.items.len);
        for (self.user_events.items, 0..) |user_event, i| {
            buf[i] = user_event.toSDLEvent();
            const res = c.SDL_PushEvent(&buf[i]);
            if (res <= 0) {
                @panic("ERROR - failed to push event to SDL event queue");
            }
        }
    }
};

pub fn buildScenario(
    allocator: Allocator,
    buffer: *Buffer,
    builder: *ScenarioBuilder,
    bg_colour: Colour,
    fg_colour: Colour,
) !platform.Platform {
    var p = platform.Platform.init();
    const surface = c.SDL_CreateRGBSurface(0, 800, 600, 32, 0, 0, 0, 0) orelse platform.crash();
    p.surface = @ptrCast(surface);

    try builder.fireEvents(allocator);
    _ = buffer.flushUserEvents(&p);
    try p.drawBuffer(buffer.*, bg_colour, fg_colour);

    return p;
}

pub fn writeScreenshot(allocator: Allocator, p: platform.Platform, screenshot_name: []const u8) !void {
    const out_data = try platformPixelDataToRGBA(allocator, p);
    defer allocator.free(out_data);
    const res = c.stbi_write_png(
        @ptrCast(screenshot_name),
        p.surface.?.w,
        p.surface.?.h,
        4,
        @ptrCast(out_data),
        4 * p.surface.?.w,
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
    const pixels: [*]u32 = @alignCast(@ptrCast(p.surface.?.pixels));
    const pixel_count: usize = @intCast(p.surface.?.w * p.surface.?.h);
    var out_data = try allocator.alloc(u8, 4 * pixel_count);
    for (pixels, 0..pixel_count) |pixel, i| {
        var r: u8 = undefined;
        var g: u8 = undefined;
        var b: u8 = undefined;
        var a: u8 = undefined;
        c.SDL_GetRGBA(pixel, @ptrCast(p.surface.?.format), &r, &g, &b, &a);
        out_data[4 * i + 0] = r;
        out_data[4 * i + 1] = g;
        out_data[4 * i + 2] = b;
        out_data[4 * i + 3] = a;
    }
    return out_data;
}
