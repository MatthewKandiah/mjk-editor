const std = @import("std");
const unicode = std.unicode;
const Font = @import("font.zig").Font;
const GlyphInfo = @import("font.zig").GlyphInfo;

pub const Utf8String = struct {
    data: []u8,

    pub const CodePoint = u21;

    pub const Iterator = struct {
        index: usize,
        data: []u8,

        const IterSelf = @This();

        pub fn init(data: []u8) !IterSelf {
            const isValid = unicode.utf8ValidateSlice(data);
            if (isValid) {
                return IterSelf{
                    .index = 0,
                    .data = data,
                };
            }
            return error.InvalidUtf8Slice;
        }

        pub fn next(self: *IterSelf) ?u21 {
            if (self.index >= self.data.len) {
                return null;
            }
            const first_byte = self.data[self.index];
            const sequence_length = unicode.utf8ByteSequenceLength(first_byte) catch unreachable;
            const res = unicode.utf8Decode(self.data[self.index .. self.index + sequence_length]) catch unreachable;
            self.index += sequence_length;
            return res;
        }
    };

    const Self = @This();

    pub fn iterate(self: Self) !Iterator {
        return Iterator.init(self.data);
    }

    pub fn width(self: Self, font: *Font, start: usize, end: usize) !usize {
        var iter = try self.iterate();
        var count: usize = 0;
        var current = iter.next();
        var res: usize = 0;
        while (current != null) : ({
            count += 1;
            current = iter.next();
        }) {
            if (count < start) continue;
            if (count >= end) break;
            const glyph = try font.get(current.?);
            res += glyph.width;
        }
        return res;
    }

    pub fn getGlyph(self: Self, font: *Font, index: usize) !GlyphInfo {
        var iter = try self.iterate();
        var count: usize = 0;
        var current = iter.next();
        while (current != null) : ({
            count += 1;
            current = iter.next();
        }) {
            if (count == index) {
                return font.get(current.?);
            }
            if (count < index - 1) continue;
        }
        return error.GetGlyphFailed;
    }
};
