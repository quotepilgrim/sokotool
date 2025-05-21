# Sokotool

A Sokoban clone made with LÖVE, containing an integrated level editor
and file browser. The name was chosen hastily and is subject to change.

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

* **Right mouse button** or **tab**: open tile selector.
* **Left mouse button**: place tile.
* **Middle mouse button**: select tile under cursor.
* **Shift** + (**W, A, S, D** or **arrow keys**): move level.
* **Ctrl + S**: save level.
* **E**: switch to play mode.

### Menu/File Browser
* **Up arrow**: highlight previous item.
* **Down arrow**: highlight next item.
* **Enter** or **left mouse button**: select highlighted item.  
  (Left click outside of the listed items closes the menu/browser.)

### Menu
* **Escape**: close menu.
* **Q**: quit game.

### File Browser
* **Escape or right mouse button**: open menu.
* **Mouse wheel**: scroll list.
* **PageUp**: previous page.
* **PageDown**: next page.

**NOTE:** The "delete level" and "delete directory" options from the menu will
delete the currently selected item in the file browser, rather than let you
choose an item to delete after selecting the option. Deleting anything other
than level files or directories only containing level files is not possible.

## Command line options
* `--dir DIRECTORY`: sets the default level directory, relative to the game's
  root. If the directory doesn't exist, the game tries to create it and place
  a dummy level file inside. If this fails the game will crash.
* `--danger-zone`: grants the file browser access outside
  of the game's root directory.
