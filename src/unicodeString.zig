const std = @import("std");
const unicode = std.unicode;

pub const Utf8String = struct {
    data: []u8,

    pub const CodePoint = u21;

    pub const Iterator = struct {
        index: usize,
        data: []u8,

        const IterSelf = @This();

        // TODO-Matt: validating on init feels more ergonomic, may be worse for performance if we are calling this frequently for long byte sequences?
        // Can consider validating on the next call instead, might even be better if we want to print something meaningful per invalid character,
        // current handling probably requires refusing to open a buffer containing invalid utf8 data. I don't hate that idea though.
        fn init(data: []const u8) !IterSelf {
            const isValid = unicode.utf8ValidateSlice(data);
            if (isValid) {
                return IterSelf{
                    .index = 0,
                    .data = data,
                };
            }
            return error.InvalidUtf8Slice;
        }

        pub fn next(self: *Self) ?u21 {
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
};
