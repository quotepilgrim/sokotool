local t = {}
local game = require("game")
local history = require("history")
local fade = require("fade")

t.tilesize = 32
t.tiles = {}
t.data = {}
t.tileimage = love.graphics.newImage("tiles.png")

function t:load()
	local width = self.tileimage:getWidth()
	local height = self.tileimage:getHeight()
	local rows = height / self.tilesize
	local cols = width / self.tilesize
	local count = 1
	for i = 0, rows - 1 do
		for j = 0, cols - 1 do
			self.tiles[count] =
				love.graphics.newQuad(j * self.tilesize, i * self.tilesize, self.tilesize, self.tilesize, width, height)
			count = count + 1
		end
	end
end

function t.is_ground(tile)
	return tile == 1 or tile == 5
end

function t.is_box(tile)
	return tile == 3 or tile == 4
end

function t:check_goals()
	for _, row in ipairs(self.data.grid) do
		for _, tile in ipairs(row) do
			if tile == 3 or tile == 5 then
				return
			end
		end
	end
	self.player.frozen = true
	fade:start("out", 2, function()
		fade:start("in", 2, function()
			self.player.frozen = false
		end)
		local id = game.list.ids[game.levelfile] % #game.list.levels + 1
		game.set_level(game.list.levels[id])
	end)
end

function t:draw()
	for j, row in ipairs(self.data.grid) do
		for i, tile in ipairs(row) do
			local quad = self.tiles[tile]
			if quad then
				love.graphics.draw(self.tileimage, quad, (i - 1) * self.tilesize, (j - 1) * self.tilesize)
			end
		end
	end
end

function t:move_box(x, y, dir)
	local box = self.data.grid[y][x]
	local nx, ny = x + game.dirs[dir][1], y + game.dirs[dir][2]
	if not self.data.grid[ny] then
		return false
	end
	if not self.is_box(box) then
		return false
	end
	local ground, target
	if box == 3 then
		ground = 1
	else
		ground = 5
	end
	target = self.data.grid[ny][nx]
	if target == 1 then
		history:push(self.data.grid, self.player.x, self.player.y)
		self.data.grid[ny][nx] = 3
	elseif target == 5 then
		history:push(self.data.grid, self.player.x, self.player.y)
		self.data.grid[ny][nx] = 4
	else
		return false
	end
	self.data.grid[y][x] = ground
	return true
end

return t
