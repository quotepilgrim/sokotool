# Sokotool

A Sokoban clone with integrated level editor and file browser. The name was chosen hastily and is subject to change.

## Controls

### Global
* **PageUp**: Load previous level.
* **PageDown**: Load next level.
* **Escape**: Open menu.
* **B**: Open file browser.

### Play mode

* **W, A, S, D** or **arrow keys**: move.
* **Z** or **backspace**: undo last push.
* **R** or **Home**: reset level.
* **E**: switch to editor mode.

### Edit mode

* **Right mouse button** or **tab**: Open tile selector.
* **Left mouse button**: Place tile.
* **Middle mouse button**: Select tile under cursor.
* **Shift** + (**W, A, S, D** or **arrow keys**): Move level.
* **Ctrl + S**: Save level.

### Menu/File Browser
* **Up arrow**: Highlight previous item.
* **Down arrow**: Highlight next item.
* **Enter** or **left mouse button**: Select highlighted item.  
  (Left click outside of the listed items closes the menu/browser.)

### Menu
* **Escape**: Close menu.
* **Q**: quit game.

### File Browser
* **Right mouse button**: Open menu.
* **Mouse wheel**: Scroll list.
* **PageUp**: Previous page.
* **PageDown**: Next page.

**NOTE:** The "delete level" and "delete directory" options from the menu will
delete the currently selected item in the file browser, rather than let you
choose an item to delete after selecting the option. Deleting anything other
than level files or directories only containing level files is not possible.
