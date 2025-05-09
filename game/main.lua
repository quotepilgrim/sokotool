require("table_func")
local tile_image, level, list, bx, by, font, level_file, blank
local events = require("events")
local file_browser = require("file_browser")
local history = require("history")
local input_path = require("input_path")
local level_io = require("level_io")
local msg = require("message")
local fade = require("fade")
local root = love.filesystem.getSourceBaseDirectory()
local level_dir = root .. "/levels"
local old_dir = level_dir
local state = "main"
local prev_state = state
local tile_size = 32

local ghost = {}
local player = {}
local tiles = {}
local mouse_state = { [1] = false, [2] = false, [3] = false }

local game = {
	main = {},
	editor = {},
	menu = {},
	input = {},
}

local dirs = {
	up = { 0, -1 },
	down = { 0, 1 },
	left = { -1, 0 },
	right = { 1, 0 },
}

local selector = {
	x = 0,
	y = 0,
	tiles = { { 1, 5, 2 }, { 3, 4, 0 }, { -1 } },
	enabled = false,
	hidden = false,
}

function game.set_state(new_state)
	if new_state == state then
		return
	end
	prev_state = state
	state = new_state
	player.sprite = player.sprites[state] or player.sprite
end

local function index_table(t)
	local indices = {}
	for i, v in ipairs(t) do
		indices[v] = i
	end
	return indices
end

local function generate_list()
	list = level_io.load("list.txt")
	if not list then
		list = { levels = table.slice(file_browser.contents, 2) }
	elseif not list.levels then
		msg:show("file is not a valid list.", "error")
	end
	list.ids = index_table(list.levels)
end

local function place_player()
	player.x = level.playerstart[1]
	player.y = level.playerstart[2]
end

local function set_level(filename)
	local new_level = level_io.load(filename)
	if not new_level then
		file_browser:chdir(old_dir)
		return false
	end
	level = new_level
	level_file = filename
	place_player()
	history:clear()
	old_dir = file_browser:current()
	msg:show(level.name, "title")
	return true
end

local menu = {
	x = 240,
	y = 100,
	active = 1,
	state = "main",
	options = {
		main = {
			{ "Return",     "close_menu" },
			{ "Edit level", "edit" },
			{ "Quit game",  "quit" },
		},
		editor = {
			{ "Return",        "close_menu" },
			{ "Play level",    "play" },
			{ "Browse levels", "browse" },
			{ "Save level",    "save" },
			{ "New level",     "add_level" },
			{ "Quit game",     "quit" },
		},
		browser = {
			{ "Return",           "close_menu" },
			{ "New level",        "add_level" },
			{ "Delete level",     "delete_level" },
			{ "New directory",    "add_dir" },
			{ "Delete directory", "delete_dir" },
			{ "Exit browser",     "close_browser" },
		},
	},
	actions = {
		close_menu = function()
			game.set_state(prev_state)
		end,
		edit = function()
			game.set_state("editor")
		end,
		browse = function()
			file_browser.enabled = true
			file_browser.active = 1
			selector.enabled = false
			game.set_state("editor")
		end,
		play = function()
			game.set_state("main")
		end,
		save = function()
			level.playerstart = { player.x, player.y }
			level_io.save(level, level_file)
			history:clear()
			game.set_state("editor")
		end,
		add_level = function()
			input_path.text = ""
			input_path.mode = "file"
			game.set_state("input")
		end,
		delete_level = function()
			local file = level_io.load(file_browser:get_active())
			if file and file.grid then
				os.remove(file_browser:get_active())
				file_browser:update_contents()
				generate_list()
				game.set_state(prev_state)
				return
			end
			msg:show("can't delete file that is not a level.", "error")
		end,
		add_dir = function()
			input_path.text = ""
			input_path.mode = "directory"
			game.set_state("input")
		end,
		delete_dir = function()
			local path = file_browser:get_active()
			file_browser:rmdir(path)
			game.set_state(prev_state)
		end,
		close_browser = function()
			file_browser.enabled = false
			game.set_state(prev_state)
		end,
		quit = function()
			love.event.quit()
		end,
	},
}

-- MAIN

local function is_ground(tile)
	return tile == 1 or tile == 5
end

local function is_box(tile)
	return tile == 3 or tile == 4
end

local function check_goals()
	for _, row in ipairs(level.grid) do
		for _, tile in ipairs(row) do
			if tile == 3 or tile == 5 then
				return
			end
		end
	end
	events:send("end_level")
end

local function move_box(x, y, dir)
	local box = level.grid[y][x]
	local nx, ny = x + dirs[dir][1], y + dirs[dir][2]
	if not level.grid[ny] then
		return false
	end
	if not is_box(box) then
		return false
	end
	local ground, target
	if box == 3 then
		ground = 1
	else
		ground = 5
	end
	target = level.grid[ny][nx]
	if target == 1 then
		history:push(level.grid, player.x, player.y)
		level.grid[ny][nx] = 3
	elseif target == 5 then
		history:push(level.grid, player.x, player.y)
		level.grid[ny][nx] = 4
	else
		return false
	end
	level.grid[y][x] = ground
	return true
end

function player:move(dir)
	if self.frozen then
		return
	end
	local x, y = self.x, self.y
	local nx, ny = x + dirs[dir][1], y + dirs[dir][2]
	if not level.grid[ny] then
		return
	end
	local tile = level.grid[ny][nx]
	if is_ground(tile) then
		self.x, self.y = nx, ny
	elseif move_box(nx, ny, dir) then
		self.x, self.y = nx, ny
		check_goals()
	end
end

function player:draw()
	love.graphics.draw(self.sprite, (self.x - 1) * tile_size, (self.y - 1) * tile_size)
end

local function draw_level()
	for j, row in ipairs(level.grid) do
		for i, tile in ipairs(row) do
			local quad = tiles[tile]
			if quad then
				love.graphics.draw(tile_image, quad, (i - 1) * tile_size, (j - 1) * tile_size)
			end
		end
	end
end

function game.main.update()
	if events:read("end_level") then
		player.frozen = true
		fade:start("out", 2, function()
			fade:start("in", 2, function()
				player.frozen = false
			end)
			local id = list.ids[level_file] % #list.levels + 1
			set_level(list.levels[id])
		end)
	end
end

function game.main.draw()
	draw_level()
	player:draw()
end

function game.main.keypressed(key)
	if file_browser.enabled then
		return file_browser:keypressed(key)
	end
	if key == "up" or key == "w" then
		player:move("up")
	elseif key == "down" or key == "s" then
		player:move("down")
	elseif key == "left" or key == "a" then
		player:move("left")
	elseif key == "right" or key == "d" then
		player:move("right")
	elseif key == "z" or key == "backspace" then
		local grid = history:pop()
		if grid then
			level.grid = grid
			player.x = grid.playerx
			player.y = grid.playery
		else
			place_player()
		end
	elseif key == "r" or key == "home" then
		local grid = history:get(1)
		if grid then
			level.grid = grid
			place_player()
			history:clear()
		end
	elseif key == "tab" then
		history:push(level.grid, player.x, player.y)
		game.set_state("editor")
	end
end

-- EDITOR

function selector:draw()
	if selector.hidden then
		return
	end
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", 0, 0, 640, 640)
	love.graphics.setColor(1, 1, 1, 1)
	for j, row in ipairs(selector.tiles) do
		for i, tile in ipairs(row) do
			local quad = tiles[tile]
			local x, y = self.x + (i - 1) * tile_size, self.y + (j - 1) * tile_size
			if quad then
				love.graphics.draw(tile_image, quad, x, y)
			elseif tile == 0 then
				love.graphics.draw(blank, x, y)
			elseif tile == -1 then
				love.graphics.draw(player.sprite, x, y)
			end
		end
	end
end

function ghost:draw()
	if not selector.pick then
		return
	end
	love.graphics.setColor(1, 1, 1, 0.6)
	if selector.pick == 0 then
		love.graphics.draw(blank, self.x, self.y)
	elseif selector.pick == -1 then
		love.graphics.draw(player.sprites[state], self.x, self.y)
	else
		love.graphics.draw(tile_image, tiles[selector.pick], self.x, self.y)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

function ghost:update()
	self.x, self.y =
		tile_size * math.floor((love.mouse.getX()) / tile_size), tile_size * math.floor((love.mouse.getY()) / tile_size)
end

local function shift_grid(key)
	if key == "up" or key == "w" then
		local first_row = level.grid[1]
		for row = 1, #level.grid - 1 do
			level.grid[row] = level.grid[row + 1]
		end
		level.grid[#level.grid] = first_row
		player.y = (player.y - 2) % #level.grid + 1
	elseif key == "down" or key == "s" then
		local last_row = level.grid[#level.grid]
		for row = #level.grid, 2, -1 do
			level.grid[row] = level.grid[row - 1]
		end
		level.grid[1] = last_row
		player.y = player.y % #level.grid + 1
	elseif key == "left" or key == "a" then
		for _, row in ipairs(level.grid) do
			local first_col = row[1]
			for col = 1, #row - 1 do
				row[col] = row[col + 1]
			end
			row[#row] = first_col
		end
		player.x = (player.x - 2) % #level.grid + 1
	elseif key == "right" or key == "d" then
		for _, row in ipairs(level.grid) do
			local last_col = row[#row]
			for col = #row, 2, -1 do
				row[col] = row[col - 1]
			end
			row[1] = last_col
		end
		player.x = player.x % #level.grid + 1
	end
end

function game.editor.update()
	if file_browser:update() then
		return
	end
	ghost:update()
	if events:read("level_select") then
		local old_dir = level_dir
		local old_file = level_file
		level_dir = file_browser:current()
		level_file = file_browser.contents[file_browser.active]
		if not set_level(level_file) then
			level_dir = old_dir
			level_file = old_file
		else
			generate_list()
		end
	end
	if love.mouse.isDown(1) and not mouse_state[1] and selector.enabled then
		mouse_state[1] = true
		selector.hidden = true
		bx, by =
			1 + math.floor((love.mouse.getX() - selector.x) / tile_size),
			1 + math.floor((love.mouse.getY() - selector.y) / tile_size)
		selector.pick = selector.tiles[by] and selector.tiles[by][bx]
	elseif love.mouse.isDown(1) and not selector.enabled then
		bx, by = 1 + math.floor(love.mouse.getX() / tile_size), 1 + math.floor(love.mouse.getY() / tile_size)
		if selector.pick and level.grid[by] and level.grid[by][bx] then
			if selector.pick == -1 then
				player.x, player.y = bx, by
			else
				level.grid[by][bx] = selector.pick
			end
		end
	elseif love.mouse.isDown(2) and not mouse_state[2] then
		mouse_state[2] = true
		selector.enabled = not selector.enabled
		selector.x = math.max(0, math.min(love.mouse.getX() - tile_size / 2, 640 - tile_size * #selector.tiles[1]))
		selector.y = math.max(0, math.min(love.mouse.getY() - tile_size / 2, 640 - tile_size * #selector.tiles))
	elseif love.mouse.isDown(3) and not mouse_state[3] then
		bx, by = 1 + math.floor(love.mouse.getX() / tile_size), 1 + math.floor(love.mouse.getY() / tile_size)
		if level.grid[by] and level.grid[by][bx] then
			selector.pick = level.grid[by][bx]
		end
		mouse_state[3] = true
	elseif not love.mouse.isDown(1) and mouse_state[1] then
		selector.enabled = false
		selector.hidden = false
		mouse_state[1] = false
	elseif not love.mouse.isDown(2) and mouse_state[2] then
		mouse_state[2] = false
	elseif not love.mouse.isDown(3) and mouse_state[3] then
		mouse_state[3] = false
	end
end

function game.editor.draw()
	draw_level()
	if selector.enabled then
		selector:draw()
	else
		ghost:draw()
	end
	player:draw()
	if file_browser.enabled then
		file_browser:draw()
	end
end

function game.editor.keypressed(key)
	if file_browser.enabled then
		return file_browser:keypressed(key)
	end
	if love.keyboard.isDown("lshift", "rshift") then
		shift_grid(key)
	elseif key == "tab" then
		selector.enabled = false
		game.set_state("main")
	elseif key == "s" and love.keyboard.isDown("lctrl", "rctrl") then
		menu.actions.save()
		msg:show("Level saved.")
	else
		return false
	end
	return true
end

-- MENU

function game.menu.draw()
	game[prev_state].draw()
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", 0, 0, 640, 640)
	love.graphics.setColor(1, 1, 1, 1)
	local y = menu.y
	for i, opt in ipairs(menu.options[menu.state]) do
		if i == menu.active then
			love.graphics.rectangle("fill", 0, y, 640, 16)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.print(opt[1], menu.x, y)
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.print(opt[1], menu.x, y)
		end
		y = y + menu.inc
	end
end

function game.menu.update()
	--
end

function game.menu.keypressed(key)
	if key == "q" then
		love.event.quit()
	elseif key == "escape" then
		game.set_state(prev_state)
	elseif key == "w" or key == "up" then
		menu.active = (menu.active - 2) % #menu.options[menu.state] + 1
	elseif key == "s" or key == "down" then
		menu.active = menu.active % #menu.options[menu.state] + 1
	elseif key == "return" then
		local action = menu.options[menu.state][menu.active][2]
		menu.actions[action]()
	else
		return false
	end
	return true
end

-- INPUT

function game.input.draw()
	game.main.draw()
	return input_path:draw()
end

function game.input.update(dt)
	if events:read("set_filename") then
		if level_io:create_level(input_path.text) then
			set_level(input_path.text)
			file_browser:update_contents()
			file_browser.enabled = false
			generate_list()
		end
		game.set_state("editor")
	elseif events:read("set_dirname") then
		file_browser:mkdir(input_path.text)
		file_browser:update_contents()
		game.set_state("editor")
	end
	return input_path:update(dt)
end

function game.input.textinput(c)
	return input_path:textinput(c)
end

function game.input.keypressed(key)
	if key == "escape" then
		game.set_state("main")
	end
	return input_path:keypressed(key)
end

----------
-- GAME --
----------

function love.load()
	while #arg > 0 do
		local v = table.remove(arg, 1)
		if v == "--dir" then
			level_dir = root .. "/" .. table.remove(arg, 1)
			print(level_dir)
		end
	end
	font = love.graphics.newFont(16)
	love.graphics.setFont(font)
	input_path:load()
	msg.load()
	if not file_browser:chdir(level_dir) then
		file_browser:mkdir(level_dir)
		file_browser:chdir(level_dir)
		if level_io:create_level("level1.txt") then
			set_level("level1.txt")
		end
	else
		generate_list()
		if not list.levels[1] then
			level_io:create_level("level1.txt")
			set_level("level1.txt")
		else
			set_level(list.levels[1])
		end
	end
	tile_image = love.graphics.newImage("tiles.png")
	player.sprites = {
		main = love.graphics.newImage("player.png"),
		editor = love.graphics.newImage("playerstart.png"),
	}
	blank = love.graphics.newImage("blank.png")
	player.sprite = player.sprites.main
	menu.inc = 2 + font:getHeight()
	local width = tile_image:getWidth()
	local height = tile_image:getHeight()
	local rows = height / tile_size
	local cols = width / tile_size
	local count = 1
	for i = 0, rows - 1 do
		for j = 0, cols - 1 do
			tiles[count] = love.graphics.newQuad(j * tile_size, i * tile_size, tile_size, tile_size, width, height)
			count = count + 1
		end
	end
	love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
	game[state].update(dt)
	fade:update(dt)
	msg:update(dt)
end

function love.draw()
	game[state].draw()
	fade:draw()
	msg:draw()
end

function love.keypressed(key)
	if game[state].keypressed and game[state].keypressed(key) then
		return true
	end
	if key == "escape" then
		if file_browser.enabled then
			menu.state = "browser"
		else
			menu.state = state
		end
		game.set_state("menu")
		menu.active = 1
	elseif key == "pagedown" then
		if not list.ids[level_file] then
			return
		end
		local id = list.ids[level_file] % #list.levels + 1
		set_level(list.levels[id])
		msg:show(level_dir:match(".*/(.*)") .. "/" .. level_file)
	elseif key == "pageup" then
		if not list.ids[level_file] then
			return
		end
		local id = (list.ids[level_file] - 2) % #list.levels + 1
		set_level(list.levels[id])
		msg:show(level_dir:match(".*/(.*)") .. "/" .. level_file)
	elseif key == "b" then
		menu.actions.browse()
	elseif key == "f1" then
		table.dump(level)
	else
		return false
	end
	return true
end

function love.textinput(c)
	if game[state].textinput then
		return game[state].textinput(c)
	end
end
