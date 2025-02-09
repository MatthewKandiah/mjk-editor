const c = @cImport({
    @cInclude("SDL_ttf.h");
});

pub const Font = struct {
    handle: *c.TTF_Font,

    const Self = @This();

    pub fn init(filepath: []const u8, ptsize: u32) !Self {
        const handle = c.TTF_OpenFont(@ptrCast(filepath), @intCast(ptsize));
        if (handle) |h| {
            return Self{ .handle = h };
        } else {
            return error.OpenFontFailed;
        }
    }
};
