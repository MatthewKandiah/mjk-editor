const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_ttf.h");
});
const Utf8String = @import("./unicodeString.zig").Utf8String;

const LookupTable = std.AutoHashMap(Utf8String.CodePoint, GlyphInfo);
const ArrayList = std.ArrayList;

pub const GlyphInfo = struct {
    data: []bool,
    width: usize,
    height: usize,
};

pub const Font = struct {
    table: LookupTable,
    // TODO-Matt: allocate new buffers when we need more space for glyph image data
    data: []bool,
    allocator: Allocator,

    const Self = @This();

    pub const BUFFER_SIZE = 1024 * 1024;

    pub fn init(allocator: Allocator, filepath: []const u8, ptsize: u32) !Self {
        const handle = c.TTF_OpenFont(@ptrCast(filepath), @intCast(ptsize)) orelse return error.OpenFontFailed;

        var table = LookupTable.init(allocator);
        const data = try allocator.alloc(bool, BUFFER_SIZE);

        var write_head: usize = 0;
        for (32..128) |char| {
            const glyph_surface: *c.SDL_Surface = c.TTF_RenderGlyph32_Solid(
                handle,
                @intCast(char),
                c.SDL_Color{ .r = 255, .g = 0, .b = 0 },
            ) orelse return error.RenderGlyphFailed;
            // check we're rendering the glyph to a paletised 8-bit surface, affects the pixel buffer layout
            std.debug.assert(glyph_surface.format.*.Rmask == 0);
            std.debug.assert(glyph_surface.format.*.Gmask == 0);
            std.debug.assert(glyph_surface.format.*.Bmask == 0);
            std.debug.assert(glyph_surface.format.*.Amask == 0);
            std.debug.assert(glyph_surface.format.*.BytesPerPixel == 1);
            const glyph_width: usize = @intCast(glyph_surface.w);
            const glyph_height: usize = @intCast(glyph_surface.h);
            const glyph_pitch: usize = @intCast(glyph_surface.pitch);
            const glyph_surface_data_raw = @as([*]u8, @ptrCast(glyph_surface.pixels))[0 .. glyph_pitch * glyph_height];
            var glyph_surface_data = try allocator.alloc(u8, glyph_height * glyph_width);
            for (0..glyph_height) |j| {
                for (0..glyph_width) |i| {
                    const read_index = j * glyph_pitch + i;
                    const write_index = j * glyph_width + i;
                    glyph_surface_data[write_index] = glyph_surface_data_raw[read_index];
                }
            }
            var write_count: usize = 0;
            for (glyph_surface_data) |byte| {
                switch (byte) {
                    0 => data[write_head + write_count] = false,
                    1 => data[write_head + write_count] = true,
                    else => return error.InvalidSDL,
                }
                write_count += 1;
            }
            const glyph_info = GlyphInfo{
                .data = data[write_head .. write_head + write_count],
                .width = glyph_width,
                .height = glyph_height,
            };
            try table.put(@intCast(char), glyph_info);
            write_head += write_count;
        }

        return Self{
            .table = table,
            .data = data,
            .allocator = allocator,
        };
    }
};
