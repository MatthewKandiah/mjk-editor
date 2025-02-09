const std = @import("std");
const Allocator = std.mem.Allocator;
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_ttf.h");
});

const LookupTable = std.AutoHashMap(u32, []bool);
const ArrayList = std.ArrayList;

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
        for (1..128) |i| {
            std.debug.print("{c}\n", .{@as(u8, @intCast(i))});
            const glyph_surface: *c.SDL_Surface = c.TTF_RenderGlyph32_Solid(
                handle,
                @intCast(i),
                c.SDL_Color{ .r = 0, .g = 0, .b = 0 },
            ) orelse return error.RenderGlyphFailed;
            // check we're rendering the glyph to a paletised 8-bit surface, affects the pixel buffer layout
            std.debug.assert(glyph_surface.format.*.Rmask == 0);
            std.debug.assert(glyph_surface.format.*.Gmask == 0);
            std.debug.assert(glyph_surface.format.*.Bmask == 0);
            std.debug.assert(glyph_surface.format.*.Amask == 0);
            std.debug.assert(glyph_surface.format.*.BytesPerPixel == 1);
            const glyph_surface_data = @as([*]u8, @ptrCast(glyph_surface.pixels))[0..@intCast(glyph_surface.w * glyph_surface.h)];
            var write_count: usize = 0;
            for (glyph_surface_data) |byte| {
                switch (byte) {
                    0 => data[write_count] = false,
                    1 => data[write_count] = true,
                    else => return error.InvalidSDL,
                }
                write_count += 1;
            }
            try table.put(@intCast(i), data[write_head..write_head + write_count]);
            write_head += write_count;
        }

        return Self{
            .table = table,
            .data = data,
            .allocator = allocator,
        };
    }
};
