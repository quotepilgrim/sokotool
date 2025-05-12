local t = {}
local game = require("game")

t.sprites = {
    main = love.graphics.newImage("player.png"),
    editor = love.graphics.newImage("playerstart.png"),
}

t.sprite = t.sprites.main

function t:move(dir)
    if self.frozen then
        return
    end
    local x, y = self.x, self.y
    local nx, ny = x + game.dirs[dir][1], y + game.dirs[dir][2]
    if not self.level.data.grid[ny] then
        return
    end
    local tile = self.level.data.grid[ny][nx]
    if self.level.is_ground(tile) then
        self.x, self.y = nx, ny
    elseif self.level:move_box(nx, ny, dir) then
        self.x, self.y = nx, ny
        self.level:check_goals()
    end
end

function t:draw()
    love.graphics.draw(self.sprite, (self.x - 1) * self.level.tilesize, (self.y - 1) * self.level.tilesize)
end

return t
