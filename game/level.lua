local t = {}
local game = require("game")
local history = require("history")
local events = require("events")

t.tilesize = 32
t.tiles = {}

function t.is_ground(tile)
    return tile == 1 or tile == 5
end

function t.is_box(tile)
    return tile == 3 or tile == 4
end

function t.check_goals()
    for _, row in ipairs(game.level.grid) do
        for _, tile in ipairs(row) do
            if tile == 3 or tile == 5 then
                return
            end
        end
    end
    events:send("end_level")
end

function t:draw()
	for j, row in ipairs(game.level.grid) do
		for i, tile in ipairs(row) do
			local quad = self.tiles[tile]
			if quad then
				love.graphics.draw(self.tileimage, quad, (i - 1) * self.tilesize, (j - 1) * self.tilesize)
			end
		end
	end
end

function t:move_box(x, y, dir)
    local box = game.level.grid[y][x]
    local nx, ny = x + game.dirs[dir][1], y + game.dirs[dir][2]
    if not game.level.grid[ny] then
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
    target = game.level.grid[ny][nx]
    if target == 1 then
        history:push(game.level.grid, game.player.x, game.player.y)
        game.level.grid[ny][nx] = 3
    elseif target == 5 then
        history:push(game.level.grid, game.player.x, game.player.y)
        game.level.grid[ny][nx] = 4
    else
        return false
    end
    game.level.grid[y][x] = ground
    return true
end

return t
