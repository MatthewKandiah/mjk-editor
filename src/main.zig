const std = @import("std");
const lib = @import("./lib.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

// TODO-Matt: Ignoring the complexity that UTF-8 characters may be encoded as several bytes
// I think this means I'll be fine using ASCII characters, but will break if you add an emoji
// std.unicode probably has all the tools needed to deal with UTF-8 properly

const fg_colour = c.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 0 };
const bg_colour = c.SDL_Color{ .r = 0, .g = 0, .b = 64, .a = 0 };
const cursor_bg_colour = c.SDL_Color{ .r = 122, .g = 0, .b = 0, .a = 0 };

pub fn main() !void {
    const sdl_init = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_EVENTS);
    assert(sdl_init == 0, "ERROR - SDL_Init failed: {}", .{sdl_init});

    const ttf_init = c.TTF_Init();
    assert(ttf_init == 0, "ERROR - TTF_Init failed: {}", .{ttf_init});

    const file = try std.fs.cwd().openFile("test.txt", std.fs.File.OpenFlags{ .mode = .read_write });
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var lines = std.ArrayList(std.ArrayList(u8)).init(allocator);
    var file_reader = file.reader();
    // TODO-Matt: slightly odd to just crash on a long line, would be nice to handle failure more gracefully
    while (try file_reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 1_000)) |line| {
        var alloc_line = try allocator.alloc(u8, line.len + 1);
        std.mem.copyForwards(u8, alloc_line, line);
        // append null byte because TTF rendering expects a null-terminated c string
        alloc_line[line.len] = 0;
        const line_array_list = std.ArrayList(u8).fromOwnedSlice(allocator, alloc_line);
        try lines.append(line_array_list);
    }

    const ubuntu_mono_font = c.TTF_OpenFont("./font/ubuntu-mono/ubuntu_mono.ttf", 24) orelse fatal("ERROR - Loading Ubuntu Mono font failed", .{});
    const fixed_width_res = c.TTF_FontFaceIsFixedWidth(ubuntu_mono_font);
    assert(fixed_width_res != 0, "ERROR - Only fixed width fonts supported", .{});

    const size_test_surface = c.TTF_RenderText_Solid(ubuntu_mono_font, "a", fg_colour);
    const ubuntu_mono_font_height: usize = @intCast(size_test_surface.*.h);
    const ubuntu_mono_font_width: usize = @intCast(size_test_surface.*.w);
    defer c.TTF_CloseFont(ubuntu_mono_font);

    const window = c.SDL_CreateWindow(
        "mjk",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        800,
        600,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse fatal("ERROR - SDL_CreateWindow failed", .{});
    var window_surface = c.SDL_GetWindowSurface(window);

    var event: c.SDL_Event = undefined;
    var running = true;
    var cursor_pos = Pos{
        .x = 0,
        .y = 0,
    };
    while (running) {
        while (c.SDL_PollEvent(@ptrCast(&event)) != 0) {
            if (event.type == c.SDL_QUIT) {
                running = false;
            } else if (event.type == c.SDL_WINDOWEVENT) {
                window_surface = c.SDL_GetWindowSurface(window);
            } else if (event.type == c.SDL_KEYDOWN) {
                switch (event.key.keysym.sym) {
                    c.SDLK_ESCAPE => running = false,
                    c.SDLK_DOWN => handleMoveDown(lines, &cursor_pos),
                    c.SDLK_UP => handleMoveUp(lines, &cursor_pos),
                    c.SDLK_RIGHT => handleMoveRight(lines, &cursor_pos),
                    c.SDLK_LEFT => handleMoveLeft(&cursor_pos),
                    c.SDLK_a => try insert(lines, &cursor_pos, 'a'),
                    c.SDLK_b => try insert(lines, &cursor_pos, 'b'),
                    c.SDLK_c => try insert(lines, &cursor_pos, 'c'),
                    c.SDLK_d => try insert(lines, &cursor_pos, 'd'),
                    c.SDLK_e => try insert(lines, &cursor_pos, 'e'),
                    c.SDLK_f => try insert(lines, &cursor_pos, 'f'),
                    c.SDLK_g => try insert(lines, &cursor_pos, 'g'),
                    c.SDLK_h => try insert(lines, &cursor_pos, 'h'),
                    c.SDLK_i => try insert(lines, &cursor_pos, 'i'),
                    c.SDLK_j => try insert(lines, &cursor_pos, 'j'),
                    c.SDLK_k => try insert(lines, &cursor_pos, 'k'),
                    c.SDLK_l => try insert(lines, &cursor_pos, 'l'),
                    c.SDLK_m => try insert(lines, &cursor_pos, 'm'),
                    c.SDLK_n => try insert(lines, &cursor_pos, 'n'),
                    c.SDLK_o => try insert(lines, &cursor_pos, 'o'),
                    c.SDLK_p => try insert(lines, &cursor_pos, 'p'),
                    c.SDLK_q => try insert(lines, &cursor_pos, 'q'),
                    c.SDLK_r => try insert(lines, &cursor_pos, 'r'),
                    c.SDLK_s => try insert(lines, &cursor_pos, 's'),
                    c.SDLK_t => try insert(lines, &cursor_pos, 't'),
                    c.SDLK_u => try insert(lines, &cursor_pos, 'u'),
                    c.SDLK_v => try insert(lines, &cursor_pos, 'v'),
                    c.SDLK_w => try insert(lines, &cursor_pos, 'w'),
                    c.SDLK_x => try insert(lines, &cursor_pos, 'x'),
                    c.SDLK_y => try insert(lines, &cursor_pos, 'y'),
                    c.SDLK_z => try insert(lines, &cursor_pos, 'z'),
                    else => std.debug.print("unhandled key down event\n", .{}),
                }
            }
        }

        const fill_res = c.SDL_FillRect(
            window_surface,
            @ptrCast(&window_surface.*.clip_rect),
            c.SDL_MapRGB(
                window_surface.*.format,
                bg_colour.r,
                bg_colour.g,
                bg_colour.b,
            ),
        );
        assert(fill_res == 0, "ERROR - SDL_FillRect failed: {}", .{fill_res});

        const cursor_rect = c.SDL_Rect{
            .x = @intCast(ubuntu_mono_font_width * cursor_pos.x),
            .y = @intCast(ubuntu_mono_font_height * cursor_pos.y),
            .w = @intCast(ubuntu_mono_font_width),
            .h = @intCast(ubuntu_mono_font_height),
        };
        const cursor_fill_res = c.SDL_FillRect(
            window_surface,
            @ptrCast(&cursor_rect),
            c.SDL_MapRGB(
                window_surface.*.format,
                cursor_bg_colour.r,
                cursor_bg_colour.g,
                cursor_bg_colour.b,
            ),
        );
        assert(cursor_fill_res == 0, "ERROR - SDL_FillRect for cursor bg failed: {}", .{cursor_fill_res});

        for (lines.items, 0..) |line, i| {
            const text_surface = c.TTF_RenderText_Solid(ubuntu_mono_font, @ptrCast(line.items), fg_colour);
            const src_rect = text_surface.*.clip_rect;
            var dst_rect = c.SDL_Rect{
                .x = 0,
                .y = text_surface.*.h * @as(c_int, @intCast(i)),
                .w = src_rect.w,
                .h = src_rect.h,
            };
            const blit_res = c.SDL_BlitSurface(
                text_surface,
                @ptrCast(&src_rect),
                window_surface,
                @ptrCast(&dst_rect),
            );
            assert(blit_res == 0, "ERROR - SDL_BlibSurface failed: {}", .{blit_res});
        }

        const update_res = c.SDL_UpdateWindowSurface(window);
        assert(update_res == 0, "ERROR - SDL_UpdateWindowSurface failed: {}", .{update_res});
    }
}

pub const Pos = struct {
    x: usize,
    y: usize,
};

pub fn handleMoveRight(lines: std.ArrayList(std.ArrayList(u8)), cursor_pos: *Pos) void {
    if (lines.items[cursor_pos.*.y].items.len > cursor_pos.*.x + 1) {
        cursor_pos.*.x += 1;
    }
}

pub fn handleMoveLeft(cursor_pos: *Pos) void {
    if (cursor_pos.*.x > 0) {
        cursor_pos.*.x -= 1;
    }
}

pub fn handleMoveUp(lines: std.ArrayList(std.ArrayList(u8)), cursor_pos: *Pos) void {
    if (cursor_pos.*.y > 0) {
        cursor_pos.*.y -= 1;
    }
    if (lines.items[cursor_pos.*.y].items.len <= cursor_pos.*.x) {
        cursor_pos.*.x = lines.items[cursor_pos.*.y].items.len - 1;
    }
}

pub fn handleMoveDown(lines: std.ArrayList(std.ArrayList(u8)), cursor_pos: *Pos) void {
    if (lines.items.len > cursor_pos.*.y + 1) {
        cursor_pos.*.y += 1;
    }
    if (lines.items[cursor_pos.*.y].items.len <= cursor_pos.*.x) {
        cursor_pos.*.x = lines.items[cursor_pos.*.y].items.len - 1;
    }
}

pub fn insert(lines: std.ArrayList(std.ArrayList(u8)), cursor_pos: *Pos, char: u8) !void {
    try lines.items[cursor_pos.*.y].insert(cursor_pos.*.x, char);
    cursor_pos.*.x += 1;
}

pub fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt, args);
    std.debug.print("\n", .{});
    std.process.exit(1);
}

pub fn assert(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        fatal(fmt, args);
    }
}
