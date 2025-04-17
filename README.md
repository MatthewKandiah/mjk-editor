# mjk-editor
## GOALS
- Modal editor, essentially cloning the vim motions I actually use
- support multiple open buffers
- Shell integration, want to be able to easily send input from buffer to shell command, and take output from shell command and write to (current or new) buffer

## TODO
### Profiling
- measure frame rendering time
- measure memory usage (stack and heap)
  
### More sensible text buffer data structure
- going to stick with this ArrayList of ArrayLists for now, let's see how far that simple idea can stretch before we need something more complex

### More sensible text rendering
- use a fixed font size for now, might be interesting to either regenerate the atlas on changing font size, or possibly to generate some slightly different sized atlases, and use scaling logic in the drawing logic to handle zooming in / out
- how hard would it be to create a texture from our rasterised font and render the screen on the gpu?