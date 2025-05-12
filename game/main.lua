require("table_func")
local list, bx, by, font, blank
local events = require("events")
local file_browser = require("file_browser")
local history = require("history")
local input_path = require("input_path")
local level_io = require("level_io")
local msg = require("message")
local fade = require("fade")
local game = require("game")
local level = require("level")
local menu = require("menu")
local root = love.filesystem.getSourceBaseDirectory()
local level_dir = root .. "/levels"
local old_dir = level_dir

local ghost = {}
local mouse_state = { [1] = false, [2] = false, [3] = false }

local selector = {
	x = 0,
	y = 0,
	tiles = { { 1, 5, 2 }, { 3, 4, 0 }, { -1 } },
	enabled = false,
	hidden = false,
}

local function index_table(t)
	local indices = {}
	for i, v in ipairs(t) do
		indices[v] = i
	end
	return indices
end

function level.generate_list()
	list = level_io.load("list.txt")
	if not list then
		list = { levels = table.slice(file_browser.contents, 2) }
	elseif not list.levels then
		msg:show("file is not a valid list.", "error")
	end
	list.ids = index_table(list.levels)
end

local function place_player()
	game.player.x = game.level.playerstart[1]
	game.player.y = game.level.playerstart[2]
end

local function set_level(filename)
	local new_level = level_io.load(filename)
	if not new_level then
		file_browser:chdir(old_dir)
		return false
	end
	game.level = new_level
	game.levelfile = filename
	place_player()
	history:clear()
	old_dir = file_browser:current()
	msg:show(game.level.name, "title")
	return true
end


-- MAIN

function game.states.main.update()
	if events:read("end_level") then
		game.player.frozen = true
		fade:start("out", 2, function()
			fade:start("in", 2, function()
				game.player.frozen = false
			end)
			local id = list.ids[game.levelfile] % #list.levels + 1
			set_level(list.levels[id])
		end)
	end
end

function game.states.main.draw()
	level:draw()
	game.player:draw()
end

function game.states.main.keypressed(key)
	if file_browser.enabled then
		return file_browser:keypressed(key)
	end
	if key == "up" or key == "w" then
		game.player:move("up")
	elseif key == "down" or key == "s" then
		game.player:move("down")
	elseif key == "left" or key == "a" then
		game.player:move("left")
	elseif key == "right" or key == "d" then
		game.player:move("right")
	elseif key == "z" or key == "backspace" then
		local grid = history:pop()
		if grid then
			game.level.grid = grid
			game.player.x = grid.playerx
			game.player.y = grid.playery
		else
			place_player()
		end
	elseif key == "r" or key == "home" then
		local grid = history:get(1)
		if grid then
			game.level.grid = grid
			place_player()
			history:clear()
		end
	elseif key == "tab" then
		history:push(game.level.grid, game.player.x, game.player.y)
		game:set_state("editor")
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
			local quad = level.tiles[tile]
			local x, y = self.x + (i - 1) * level.tilesize, self.y + (j - 1) * level.tilesize
			if quad then
				love.graphics.draw(level.tileimage, quad, x, y)
			elseif tile == 0 then
				love.graphics.draw(blank, x, y)
			elseif tile == -1 then
				love.graphics.draw(game.player.sprite, x, y)
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
		love.graphics.draw(game.player.sprites[game.state], self.x, self.y)
	else
		love.graphics.draw(level.tileimage, level.tiles[selector.pick], self.x, self.y)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

function ghost:update()
	self.x, self.y =
		level.tilesize * math.floor((love.mouse.getX()) / level.tilesize),
		level.tilesize * math.floor((love.mouse.getY()) / level.tilesize)
end

local function shift_grid(key)
	if key == "up" or key == "w" then
		local first_row = game.level.grid[1]
		for row = 1, #game.level.grid - 1 do
			game.level.grid[row] = game.level.grid[row + 1]
		end
		game.level.grid[#game.level.grid] = first_row
		game.player.y = (game.player.y - 2) % #game.level.grid + 1
	elseif key == "down" or key == "s" then
		local last_row = game.level.grid[#game.level.grid]
		for row = #game.level.grid, 2, -1 do
			game.level.grid[row] = game.level.grid[row - 1]
		end
		game.level.grid[1] = last_row
		game.player.y = game.player.y % #game.level.grid + 1
	elseif key == "left" or key == "a" then
		for _, row in ipairs(game.level.grid) do
			local first_col = row[1]
			for col = 1, #row - 1 do
				row[col] = row[col + 1]
			end
			row[#row] = first_col
		end
		game.player.x = (game.player.x - 2) % #game.level.grid + 1
	elseif key == "right" or key == "d" then
		for _, row in ipairs(game.level.grid) do
			local last_col = row[#row]
			for col = #row, 2, -1 do
				row[col] = row[col - 1]
			end
			row[1] = last_col
		end
		game.player.x = game.player.x % #game.level.grid + 1
	end
end

function game.states.editor.update()
	if file_browser:update() then
		return
	end
	ghost:update()
	if events:read("level_select") then
		local old_dir = level_dir
		local old_file = game.levelfile
		level_dir = file_browser:current()
		game.levelfile = file_browser.contents[file_browser.active]
		if not set_level(game.levelfile) then
			level_dir = old_dir
			game.levelfile = old_file
		else
			level.generate_list()
		end
	end
	if love.mouse.isDown(1) and not mouse_state[1] and selector.enabled then
		mouse_state[1] = true
		selector.hidden = true
		bx, by =
			1 + math.floor((love.mouse.getX() - selector.x) / level.tilesize),
			1 + math.floor((love.mouse.getY() - selector.y) / level.tilesize)
		selector.pick = selector.tiles[by] and selector.tiles[by][bx]
	elseif love.mouse.isDown(1) and not selector.enabled then
		bx, by = 1 + math.floor(love.mouse.getX() / level.tilesize), 1 + math.floor(love.mouse.getY() / level.tilesize)
		if selector.pick and game.level.grid[by] and game.level.grid[by][bx] then
			if selector.pick == -1 then
				game.player.x, game.player.y = bx, by
			else
				game.level.grid[by][bx] = selector.pick
			end
		end
	elseif love.mouse.isDown(2) and not mouse_state[2] then
		mouse_state[2] = true
		selector.enabled = not selector.enabled
		selector.x = math.max(0,
			math.min(love.mouse.getX() - level.tilesize / 2, 640 - level.tilesize * #selector.tiles[1]))
		selector.y = math.max(0, math.min(love.mouse.getY() - level.tilesize / 2, 640 - level.tilesize * #selector.tiles))
	elseif love.mouse.isDown(3) and not mouse_state[3] then
		bx, by = 1 + math.floor(love.mouse.getX() / level.tilesize), 1 + math.floor(love.mouse.getY() / level.tilesize)
		if game.level.grid[by] and game.level.grid[by][bx] then
			selector.pick = game.level.grid[by][bx]
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

function game.states.editor.draw()
	level:draw()
	if selector.enabled then
		selector:draw()
	else
		ghost:draw()
	end
	game.player:draw()
	if file_browser.enabled then
		file_browser:draw()
	end
end

function game.states.editor.keypressed(key)
	if file_browser.enabled then
		return file_browser:keypressed(key)
	end
	if love.keyboard.isDown("lshift", "rshift") then
		shift_grid(key)
	elseif key == "tab" then
		selector.enabled = false
		game:set_state("main")
	elseif key == "s" and love.keyboard.isDown("lctrl", "rctrl") then
		menu.actions.save()
		msg:show("Level saved.")
	else
		return false
	end
	return true
end

-- MENU

function game.states.menu.draw()
	game.states[game.prev_state].draw()
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

function game.states.menu.update()
	--
end

function game.states.menu.keypressed(key)
	if key == "q" then
		love.event.quit()
	elseif key == "escape" then
		game:set_state(game.prev_state)
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

function game.states.input.draw()
	game.states.main.draw()
	return input_path:draw()
end

function game.states.input.update(dt)
	if events:read("set_filename") then
		if level_io:create_level(input_path.text) then
			set_level(input_path.text)
			file_browser:update_contents()
			file_browser.enabled = false
			level.generate_list()
		end
		game:set_state("editor")
	elseif events:read("set_dirname") then
		file_browser:mkdir(input_path.text)
		file_browser:update_contents()
		game:set_state("editor")
	end
	return input_path:update(dt)
end

function game.states.input.textinput(c)
	return input_path:textinput(c)
end

function game.states.input.keypressed(key)
	if key == "escape" then
		game:set_state("main")
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
	game.player = require("player")
	if not file_browser:chdir(level_dir) then
		file_browser:mkdir(level_dir)
		file_browser:chdir(level_dir)
		if level_io:create_level("level1.txt") then
			set_level("level1.txt")
		end
	else
		level.generate_list()
		if not list.levels[1] then
			level_io:create_level("level1.txt")
			set_level("level1.txt")
		else
			set_level(list.levels[1])
		end
	end
	level.tileimage = love.graphics.newImage("tiles.png")
	game.player.sprites = {
		main = love.graphics.newImage("player.png"),
		editor = love.graphics.newImage("playerstart.png"),
	}
	blank = love.graphics.newImage("blank.png")
	game.player.sprite = game.player.sprites.main
	menu.inc = 2 + font:getHeight()
	local width = level.tileimage:getWidth()
	local height = level.tileimage:getHeight()
	local rows = height / level.tilesize
	local cols = width / level.tilesize
	local count = 1
	for i = 0, rows - 1 do
		for j = 0, cols - 1 do
			level.tiles[count] = love.graphics.newQuad(j * level.tilesize, i * level.tilesize, level.tilesize,
				level.tilesize, width, height)
			count = count + 1
		end
	end
	love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
	game.states[game.state].update(dt)
	fade:update(dt)
	msg:update(dt)
end

function love.draw()
	game.states[game.state].draw()
	fade:draw()
	msg:draw()
end

function love.keypressed(key)
	if game.states[game.state].keypressed and game.states[game.state].keypressed(key) then
		return true
	end
	if key == "escape" then
		if file_browser.enabled then
			menu.state = "browser"
		else
			menu.state = game.state
		end
		game:set_state("menu")
		menu.active = 1
	elseif key == "pagedown" then
		if not list.ids[game.levelfile] then
			return
		end
		local id = list.ids[game.levelfile] % #list.levels + 1
		set_level(list.levels[id])
		msg:show(level_dir:match(".*/(.*)") .. "/" .. game.levelfile)
	elseif key == "pageup" then
		if not list.ids[game.levelfile] then
			return
		end
		local id = (list.ids[game.levelfile] - 2) % #list.levels + 1
		set_level(list.levels[id])
		msg:show(level_dir:match(".*/(.*)") .. "/" .. game.levelfile)
	elseif key == "b" then
		menu.actions.browse()
		selector.enabled = false
	elseif key == "f1" then
		table.dump(game.level)
	else
		return false
	end
	return true
end

function love.textinput(c)
	if game.states[game.state].textinput then
		return game.states[game.state].textinput(c)
	end
end
