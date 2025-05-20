local t = {}
local file_browser = require("file_browser")
local game = require("game")
local history = require("history")
local input_path = require("input_path")
local level = require("level")
local level_io = require("level_io")
local msg = require("message")

t.x = 240
t.y = 100
t.active = 1
t.state = "main"
t.inc = 2 + love.graphics.getFont():getHeight()
t.height = {}

t.options = {
	main = {
		{ "Return", "close_menu" },
		{ "Edit level", "edit" },
		{ "Browse levels", "browse" },
		{ "Quit game", "quit" },
	},
	editor = {
		{ "Return", "close_menu" },
		{ "Play level", "play" },
		{ "Browse levels", "browse" },
		{ "Save level", "save" },
		{ "New level", "add_level" },
		{ "Quit game", "quit" },
	},
	browser = {
		{ "Return", "close_menu" },
		{ "New level", "add_level" },
		{ "Delete level", "delete_level" },
		{ "New directory", "add_dir" },
		{ "Delete directory", "delete_dir" },
		{ "Exit browser", "close_browser" },
	},
}
t.actions = {
	close_menu = function()
		game:set_state(game.prev_state)
	end,
	edit = function()
		game:set_state("editor")
	end,
	browse = function()
		file_browser.enabled = true
		file_browser.active = 1
		game:set_state(game.prev_state)
	end,
	play = function()
		game:set_state("main")
	end,
	save = function()
		game.level.playerstart = { game.player.x, game.player.y }
		level_io.save(level.data, game.levelfile)
		history:clear()
		game:set_state("editor")
	end,
	add_level = function()
		input_path.text = ""
		input_path.mode = "file"
		game:set_state("input")
	end,
	delete_level = function()
		local file = level_io.load(file_browser:get_active())
		if file and file.grid then
			os.remove(file_browser:get_active())
			file_browser:update_contents()
			level.generate_list()
			game:set_state(game.prev_state)
			return
		end
		msg:show("can't delete file that is not a level.", "error")
	end,
	add_dir = function()
		input_path.text = ""
		input_path.mode = "directory"
		game:set_state("input")
	end,
	delete_dir = function()
		local path = file_browser:get_active()
		file_browser:rmdir(path)
		game:set_state(game.prev_state)
	end,
	close_browser = function()
		file_browser.enabled = false
		game:set_state(game.prev_state)
	end,
	quit = function()
		love.event.quit()
	end,
}

for k, v in pairs(t.options) do
	t.height[k] = #v * t.inc
end

return t
