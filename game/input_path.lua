local t = {}
local utf8 = require("utf8")
local events = require("events")
local timer = 0
local cursor = ""
local titles = { file = "Enter filename:", directory = "Enter directory name:" }

t.x = 100
t.y = 100
t.w = 440
t.h = 56
t.text = ""
t.mode = "file"

function t:draw()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", self.x + 8, self.y + 28, self.w - 16, 20)
	love.graphics.print(titles[self.mode], self.x + 10, self.y + 5)
	love.graphics.print(self.text .. cursor, self.x + 10, self.y + 28)
end

function t:update(dt)
	timer = timer + dt
	if timer > 0.5 then
		timer = timer - 0.5
		if cursor == "" then
			cursor = "|"
		else
			cursor = ""
		end
	end
end

function t:textinput(c)
	self.text = self.text .. c
end

function t:keypressed(key)
	if key == "backspace" then
		local byteoffset = utf8.offset(self.text, -1)
		if byteoffset then
			self.text = string.sub(self.text, 1, byteoffset - 1)
		end
	elseif key == "return" then
		if self.mode == "file" then
			events:send("set_filename")
		elseif self.mode == "directory" then
			events:send("set_dirname")
		end
	end
	return true
end

return t
