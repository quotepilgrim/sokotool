require("table_func")
local fade = require("fade")
local file_browser = require("file_browser")
local game = require("game")
local history = require("history")
local input_path = require("input_path")
local level = require("level")
local level_io = require("level_io")
local menu = require("menu")
local msg = require("message")
local player = require("player")
local bx, by, font, blank
game.root = love.filesystem.getSourceBaseDirectory()
game.leveldir = game.root .. "/levels"
game.prevdir = game.leveldir

local ghost = {}

local selector = {
	x = 0,
	y = 0,
	tiles = { { 1, 5, 2 }, { 3, 4, 0 }, { -1 } },
	enabled = false,
	hidden = false,
}

function selector:toggle(x, y)
	if not self.enabled then
		selector.x = math.max(0, math.min(x - level.tilesize / 2, 640 - level.tilesize * #selector.tiles[1]))
		selector.y = math.max(0, math.min(y - level.tilesize / 2, 640 - level.tilesize * #selector.tiles))
	end
	self.enabled = not self.enabled
end

local function index_table(t)
	local indices = {}
	for i, v in ipairs(t) do
		indices[v] = i
	end
	return indices
end

function level.generate_list()
	game.list = level_io.load("list.txt")
	if not game.list then
		game.list = { levels = table.slice(file_browser.contents, 2) }
	elseif not game.list.levels then
		msg:show("file is not a valid list.", "error")
	end
	game.list.ids = index_table(game.list.levels)
end

local function place_player()
	player.x = level.data.playerstart[1]
	player.y = level.data.playerstart[2]
end

function game.set_level(filename)
	local new_level = level_io.load(filename)
	if not new_level or not new_level.grid then
		file_browser:chdir(game.prevdir)
		return false
	end
	level.data = new_level
	game.levelfile = filename
	place_player()
	history:clear()
	game.prevdir = file_browser:current()
	msg:show(level.data.name, "title")
	if game.state == "main" then
		player:set_sprite("idle")
	end
	return true
end

-- MAIN

function game.states.main.update()
	if file_browser.enabled then
		return file_browser:update()
	end
end

function game.states.main.draw()
	level:draw()
	player:draw()
	if file_browser.enabled then
		return file_browser:draw()
	end
end

function game.states.main.keypressed(key)
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
		if player.frozen then
			return
		end
		local grid = history:pop()
		if grid then
			level.data.grid = grid
			player.x = grid.playerx
			player.y = grid.playery
		else
			place_player()
			player:set_sprite("idle")
		end
	elseif key == "r" or key == "home" then
		local grid = history:get(1)
		place_player()
		player:set_sprite("idle")
		if grid then
			level.data.grid = grid
			history:clear()
		end
	elseif key == "e" then
		history:push(level.data.grid, player.x, player.y)
		game:set_state("editor")
	end
end

function game.states.main.mousepressed(x, y, button)
	if button == 1 and file_browser.enabled then
		return file_browser:mousepressed(x, y, button)
	elseif button == 2 and file_browser.enabled then
		menu.state = "browser"
		game:set_state("menu")
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
				love.graphics.draw(player.spriteimage, player.sprites[player.sprite], x, y)
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
		love.graphics.draw(player.spriteimage, player.sprites[player.sprite], self.x, self.y)
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
		local first_row = level.data.grid[1]
		for row = 1, #level.data.grid - 1 do
			level.data.grid[row] = level.data.grid[row + 1]
		end
		level.data.grid[#level.data.grid] = first_row
		player.y = (player.y - 2) % #level.data.grid + 1
	elseif key == "down" or key == "s" then
		local last_row = level.data.grid[#level.data.grid]
		for row = #level.data.grid, 2, -1 do
			level.data.grid[row] = level.data.grid[row - 1]
		end
		level.data.grid[1] = last_row
		player.y = player.y % #level.data.grid + 1
	elseif key == "left" or key == "a" then
		for _, row in ipairs(level.data.grid) do
			local first_col = row[1]
			for col = 1, #row - 1 do
				row[col] = row[col + 1]
			end
			row[#row] = first_col
		end
		player.x = (player.x - 2) % #level.data.grid + 1
	elseif key == "right" or key == "d" then
		for _, row in ipairs(level.data.grid) do
			local last_col = row[#row]
			for col = #row, 2, -1 do
				row[col] = row[col - 1]
			end
			row[1] = last_col
		end
		player.x = player.x % #level.data.grid + 1
	end
end

function game.states.editor.update()
	if file_browser:update() then
		return
	end
	ghost:update()
	if selector.placing then
		bx, by = 1 + math.floor(love.mouse.getX() / level.tilesize), 1 + math.floor(love.mouse.getY() / level.tilesize)
		if selector.pick and level.data.grid[by] and level.data.grid[by][bx] then
			if selector.pick == -1 then
				player.x, player.y = bx, by
			else
				level.data.grid[by][bx] = selector.pick
			end
		end
	end
end

function game.states.editor.draw()
	level:draw()
	if selector.enabled then
		player:draw()
		selector:draw()
	else
		ghost:draw()
		player:draw()
	end
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
	elseif key == "e" then
		selector.enabled = false
		game:set_state("main")
	elseif key == "tab" then
		selector:toggle(game.mousex, game.mousey)
	elseif key == "s" and love.keyboard.isDown("lctrl", "rctrl") then
		menu.actions.save()
		msg:show("Level saved.")
	else
		return false
	end
	return true
end

function game.states.editor.mousepressed(x, y, button)
	if button == 1 and selector.enabled then
		selector.hidden = true
		bx, by = 1 + math.floor((x - selector.x) / level.tilesize), 1 + math.floor((y - selector.y) / level.tilesize)
		selector.pick = selector.tiles[by] and selector.tiles[by][bx]
	elseif button == 1 and file_browser.enabled then
		file_browser:mousepressed(x, y, button)
	elseif button == 1 then
		selector.placing = true
	elseif button == 2 and file_browser.enabled then
		menu.state = "browser"
		game:set_state("menu")
	elseif button == 2 then
		selector:toggle(x, y)
	elseif button == 3 then
		bx, by = 1 + math.floor(love.mouse.getX() / level.tilesize), 1 + math.floor(love.mouse.getY() / level.tilesize)
		if level.data.grid[by] and level.data.grid[by][bx] then
			selector.pick = level.data.grid[by][bx]
		end
	end
end

function game.states.editor.mousereleased(x, y, button)
	if button == 1 then
		selector.enabled = false
		selector.hidden = false
		selector.placing = false
	end
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
	if game.mouseactive then
		menu.active = math.max(1, math.min(math.ceil((game.mousey - menu.y) / menu.inc), #menu.options[menu.state]))
	end
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
		if action then
			menu.actions[action]()
		end
	else
		return false
	end
	return true
end

function game.states.menu.mousepressed(_, _, button)
	if button == 1 then
		if game.mousey < menu.y or game.mousey > menu.y + menu.height[menu.state] then
			game:set_state(game.prev_state)
			return
		end
		local action = menu.options[menu.state][menu.active][2]
		menu.actions[action]()
	end
end

-- INPUT

function game.states.input.draw()
	game.states.main.draw()
	return input_path:draw()
end

function game.states.input.update(dt)
	return input_path:update(dt)
end

function game.states.input.textinput(c)
	return input_path:textinput(c)
end

function game.states.input.keypressed(key)
	return input_path:keypressed(key)
end

----------
-- GAME --
----------

function love.load()
	while #arg > 0 do
		local v = table.remove(arg, 1)
		if v == "--dir" then
			game.leveldir = game.root .. "/" .. table.remove(arg, 1)
			print(game.leveldir)
		end
	end
	font = love.graphics.newFont(16)
	love.graphics.setFont(font)
	input_path:load()
	level:load()
	msg.load()
	player:load()
	player.level = require("level")
	level.player = require("player")
	game.player = require("player")
	blank = love.graphics.newImage("blank.png")

	if not file_browser:chdir(game.leveldir) then
		file_browser:mkdir(game.leveldir)
		file_browser:chdir(game.leveldir)
		if level_io:create_level("level1.txt") then
			file_browser:update_contents()
			game.set_level("level1.txt")
		end
	else
		level.generate_list()
		if not game.list.levels[1] then
			level_io:create_level("level1.txt")
			file_browser:update_contents()
			game.set_level("level1.txt")
		else
			game.set_level(game.list.levels[1])
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
	game.mouseactive = false
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
		if not game.list.ids[game.levelfile] then
			return
		end
		local id = game.list.ids[game.levelfile] % #game.list.levels + 1
		game.set_level(game.list.levels[id])
		msg:show(game.leveldir:match(".*/(.*)") .. "/" .. game.levelfile)
	elseif key == "pageup" then
		if not game.list.ids[game.levelfile] then
			return
		end
		local id = (game.list.ids[game.levelfile] - 2) % #game.list.levels + 1
		game.set_level(game.list.levels[id])
		msg:show(game.leveldir:match(".*/(.*)") .. "/" .. game.levelfile)
	elseif key == "b" then
		menu.actions.browse()
		selector.enabled = false
	elseif key == "f1" then
		table.dump(level.data)
	else
		return false
	end
	return true
end

function love.mousepressed(x, y, button)
	if game.states[game.state].mousepressed then
		return game.states[game.state].mousepressed(x, y, button)
	end
end

function love.mousereleased(x, y, button)
	if game.states[game.state].mousereleased then
		return game.states[game.state].mousereleased(x, y, button)
	end
end

function love.textinput(c)
	if game.states[game.state].textinput then
		return game.states[game.state].textinput(c)
	end
end

function love.mousemoved(x, y)
	game.mouseactive = true
	game.mousex = x
	game.mousey = y
end

function love.wheelmoved(x, y)
	if file_browser.enabled then
		return file_browser:wheelmoved(x, y)
	end
end
