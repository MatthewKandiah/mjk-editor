pub const Colour = struct {
    r: u8,
    g: u8,
    b: u8,

    const Self = @This();

    pub fn equals(self: Self, other: Colour) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b;
    }
};
