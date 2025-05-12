local t = {}
local game = require("game")
local level = require("level")

function t:move(dir)
	if self.frozen then
		return
	end
	local x, y = self.x, self.y
	local nx, ny = x + game.dirs[dir][1], y + game.dirs[dir][2]
	if not game.level.grid[ny] then
		return
	end
	local tile = game.level.grid[ny][nx]
	if level.is_ground(tile) then
		self.x, self.y = nx, ny
	elseif level:move_box(nx, ny, dir) then
		self.x, self.y = nx, ny
		level.check_goals()
	end
end

function t:draw()
	love.graphics.draw(self.sprite, (self.x - 1) * level.tilesize, (self.y - 1) * level.tilesize)
end


return t