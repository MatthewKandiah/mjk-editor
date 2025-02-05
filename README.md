# mjk-editor
## GOALS
- Experiment using more SDL features. Open, edit, and write UFT-8 encoded files. Using ttf fonts.
- Modal editor, essentially cloning the vim motions I actually use
- Shell integration, want to be able to easily send input from buffer to shell command, and take output from shell command and write to (current or new) buffer

## TODO
- [x] Open a window
- [x] Handle window close events
- [x] Handle window resizing
- [x] Display a hardcoded string in the middle of that window
- [x] Handle keyboard inputs for editing the displayed string
- [x] Read a file in
- [x] Write buffer to file

## DEFERRED
I __think__ we get these things for free by using SDL. That might not be true. They might be fun to do from scratch later.
- ttf parsing and rasterizing
- manually handle blitting displayed characters to screen
- [rope data structure](https://en.wikipedia.org/wiki/Rope_(data_structure)) - might be needed for efficient handling of large files

