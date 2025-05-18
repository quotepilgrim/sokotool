local t = {}
local game = require("game")

t.spriteimage = love.graphics.newImage("player.png")
t.width, t.height = 32, 32
t.sprites = {}
t.sprite_ids = { up = 1, down = 2, left = 3, right = 4, idle = 5, edit = 6 }
t.sprite = t.sprite_ids["idle"]

function t:load()
    local width = self.spriteimage:getWidth()
    local height = self.spriteimage:getHeight()
    local rows = height / self.height
    local cols = width / self.width
    local count = 1
    for i = 0, rows - 1 do
        for j = 0, cols - 1 do
            self.sprites[count] = love.graphics.newQuad(j * self.height, i * self.width, self.width,
                self.height, width, height)
            count = count + 1
        end
    end
end

function t:set_sprite(sprite)
    self.sprite = self.sprite_ids[sprite]
end

function t:move(dir)
    if self.frozen then
        return
    end
    local x, y = self.x, self.y
    local nx, ny = x + game.dirs[dir][1], y + game.dirs[dir][2]
    self:set_sprite(dir)
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
    love.graphics.draw(self.spriteimage, self.sprites[self.sprite], (self.x - 1) * self.width, (self.y - 1) * self
    .height)
end

return t
