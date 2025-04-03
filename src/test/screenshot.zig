const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("stb_image.h");
    @cInclude("stb_image_write.h");
    @cInclude("SDL.h");
});
const mjk = @import("mjk");
const Font = mjk.font.Font;
const platform = mjk.platform;
const Buffer = mjk.buffer.Buffer;
const Colour = mjk.colour.Colour;

fn sdlKeyDownEvent(sym: c_int) c.SDL_Event {
    return c.SDL_Event{ .key = .{ .type = c.SDL_KEYDOWN, .keysym = .{ .sym = sym } } };
}

fn sdlTextInputEvent(data: [32]u8) c.SDL_Event {
    return c.SDL_Event{ .text = .{ .type = c.SDL_TEXTINPUT, .text = data } };
}

pub const UserEvent = enum {
    right,
    left,
    up,
    down,
    escape,
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,

    const Self = @This();

    pub fn toSDLKeyDownEvent(self: Self) c.SDL_Event {
        return switch (self) {
            .right => sdlKeyDownEvent(c.SDLK_RIGHT),
            .left => sdlKeyDownEvent(c.SDLK_LEFT),
            .up => sdlKeyDownEvent(c.SDLK_UP),
            .down => sdlKeyDownEvent(c.SDLK_DOWN),
            .escape => sdlKeyDownEvent(c.SDLK_ESCAPE),
            .a => sdlKeyDownEvent(c.SDLK_a),
            .b => sdlKeyDownEvent(c.SDLK_b),
            .c => sdlKeyDownEvent(c.SDLK_c),
            .d => sdlKeyDownEvent(c.SDLK_d),
            .e => sdlKeyDownEvent(c.SDLK_e),
            .f => sdlKeyDownEvent(c.SDLK_f),
            .g => sdlKeyDownEvent(c.SDLK_g),
            .h => sdlKeyDownEvent(c.SDLK_h),
            .i => sdlKeyDownEvent(c.SDLK_i),
            .j => sdlKeyDownEvent(c.SDLK_j),
            .k => sdlKeyDownEvent(c.SDLK_k),
            .l => sdlKeyDownEvent(c.SDLK_l),
            .m => sdlKeyDownEvent(c.SDLK_m),
            .n => sdlKeyDownEvent(c.SDLK_n),
            .o => sdlKeyDownEvent(c.SDLK_o),
            .p => sdlKeyDownEvent(c.SDLK_p),
            .q => sdlKeyDownEvent(c.SDLK_q),
            .r => sdlKeyDownEvent(c.SDLK_r),
            .s => sdlKeyDownEvent(c.SDLK_s),
            .t => sdlKeyDownEvent(c.SDLK_t),
            .u => sdlKeyDownEvent(c.SDLK_u),
            .v => sdlKeyDownEvent(c.SDLK_v),
            .w => sdlKeyDownEvent(c.SDLK_w),
            .x => sdlKeyDownEvent(c.SDLK_x),
            .y => sdlKeyDownEvent(c.SDLK_y),
            .z => sdlKeyDownEvent(c.SDLK_z),
        };
    }

    pub fn toSDLTextInputEvent(self: Self) ?c.SDL_Event {
        return switch (self) {
            .right => null,
            .left => null,
            .up => null,
            .down => null,
            .escape => null,
            .a => sdlTextInputEvent(.{ 'a', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .b => sdlTextInputEvent(.{ 'b', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .c => sdlTextInputEvent(.{ 'c', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .d => sdlTextInputEvent(.{ 'd', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .e => sdlTextInputEvent(.{ 'e', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .f => sdlTextInputEvent(.{ 'f', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .g => sdlTextInputEvent(.{ 'g', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .h => sdlTextInputEvent(.{ 'h', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .i => sdlTextInputEvent(.{ 'i', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .j => sdlTextInputEvent(.{ 'j', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .k => sdlTextInputEvent(.{ 'k', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .l => sdlTextInputEvent(.{ 'l', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .m => sdlTextInputEvent(.{ 'm', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .n => sdlTextInputEvent(.{ 'n', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .o => sdlTextInputEvent(.{ 'o', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .p => sdlTextInputEvent(.{ 'p', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .q => sdlTextInputEvent(.{ 'q', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .r => sdlTextInputEvent(.{ 'r', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .s => sdlTextInputEvent(.{ 's', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .t => sdlTextInputEvent(.{ 't', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .u => sdlTextInputEvent(.{ 'u', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .v => sdlTextInputEvent(.{ 'v', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .w => sdlTextInputEvent(.{ 'w', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .x => sdlTextInputEvent(.{ 'x', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .y => sdlTextInputEvent(.{ 'y', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
            .z => sdlTextInputEvent(.{ 'z', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
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

    pub fn doRepeated(self: *Self, event: UserEvent, n: usize) *Self {
        for (0..n) |_| {
            _ = self.do(event);
        }
        return self;
    }

    pub fn fireEvents(self: Self, allocator: Allocator) !void {
        var buf = try allocator.alloc(c.SDL_Event, 2 * self.user_events.items.len);
        var count: usize = 0;

        for (self.user_events.items) |user_event| {
            const keyDownEvent = user_event.toSDLKeyDownEvent();
            const maybeTextInputEvent = user_event.toSDLTextInputEvent();
            if (maybeTextInputEvent) |textInputEvent| {
                buf[count] = keyDownEvent;
                buf[count + 1] = textInputEvent;
                count += 2;
            } else {
                buf[count] = keyDownEvent;
                count += 1;
            }
        }

        for (0..count) |i| {
            const res = c.SDL_PushEvent(&buf[i]);
            if (res <= 0) {
                @panic("ERROR - failed to push event to SDL event queue");
            }
        }

        allocator.free(buf);
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
    p.clear(bg_colour);

    try builder.fireEvents(allocator);
    var redraw_needed = false;
    _ = try buffer.flushUserEvents(&p, &redraw_needed);
    try p.drawBuffer(buffer.*, bg_colour, fg_colour);

    return p;
}

pub fn screenshotTest(
    allocator: Allocator,
    input_path: []const u8,
    screenshot_name: []const u8,
    builder: *ScenarioBuilder,
    generate: bool,
) !bool {
    const font_filepath = "font/roboto/roboto-regular.ttf";
    const font_size = 36;
    var font = try Font.init(allocator, font_filepath, font_size);
    try font.fillBasicGlyphs();

    const bg_colour = Colour{ .r = 64, .g = 64, .b = 64 };
    const fg_colour = Colour{ .r = 255, .g = 255, .b = 255 };

    var buffer = try platform.readFile(allocator, input_path, &font, font_size);
    const p = try buildScenario(allocator, &buffer, builder, bg_colour, fg_colour);

    if (generate) {
        try writeScreenshot(allocator, p, screenshot_name);
        return true;
    } else {
        return checkScreenshot(allocator, p, screenshot_name);
    }
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
        return error.StbiWriteFailed;
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
        return error.StbiLoadFailed;
    }
    defer c.stbi_image_free(screenshot_data);

    const pixel_count: usize = @intCast(screenshot_width * screenshot_height);
    const expected_pixel_count: usize = @intCast(p.surface.?.w * p.surface.?.h);
    if (pixel_count != p.surface.?.w * p.surface.?.h) {
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
