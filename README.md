# mjk-editor
## GOALS
- Experiment using more SDL features. Open, edit, and write UFT-8 encoded files. Using ttf fonts.
- Modal editor, essentially cloning the vim motions I actually use
- Shell integration, want to be able to easily send input from buffer to shell command, and take output from shell command and write to (current or new) buffer

## TODO
### More sensible text buffer data structure
- I've been using null terminated strings internally to use SDL text drawing, would prefer to drop this and just use slices
- sensible insert and delete functions
- going to stick with this ArrayList of ArrayLists for now, let's see how far that simple idea can stretch before we need something more complex
- can we support non-fixed-width fonts? Would need to store character widths in the buffer to allow the cursor to render in the right place

### More sensible text rendering
- allocate a large texture atlas buffer, render glyphs for alphanumeric and punctuation characters that will likely be used
- keep a hash map to lookup glyph locations in the texture atlas buffer, generate less commonly used characters when they are first used
- allocate more space if the atlas runs out
- use a fixed font size for now, might be interesting to either regenerate the atlas on changing font size, or possibly to generate some slightly different sized atlases, and use scaling logic in the drawing logic to handle zooming in / out

## DEFERRED
I __think__ we get these things for free by using SDL. That might not be true. They might be fun to do from scratch later.
- ttf parsing and rasterizing
- [rope data structure](https://en.wikipedia.org/wiki/Rope_(data_structure)) - might be needed for efficient handling of large files

