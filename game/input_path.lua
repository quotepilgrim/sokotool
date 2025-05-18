local t = {}
local utf8 = require("utf8")
local game = require("game")
local level_io = require("level_io")
local level = require("level")
local file_browser = require("file_browser")
local timer = 0
local titles = { file = "Enter filename:", directory = "Enter directory name:" }
local valid_str = "abcdefghijklmnopqrstuvwxyz1234567890_-. "
local valid_chars = {}
local font

t.x = 100
t.y = 100
t.w = 440
t.h = 56
t.text = ""
t.mode = "file"
t.draw_cursor = true

function t.load()
	font = love.graphics.getFont()
	for i = 1, #valid_str do
		local char = valid_str:sub(i, i)
		valid_chars[char] = true
		valid_chars[char:upper()] = true
	end
end

function t:draw()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("line", self.x + 8, self.y + 28, self.w - 16, 20)
	love.graphics.print(titles[self.mode], self.x + 10, self.y + 5)
	love.graphics.print(self.text, self.x + 10, self.y + 28)
	if self.draw_cursor then
		love.graphics.rectangle("fill", self.x + 11 + font:getWidth(self.text), self.y + 30, 2, 16)
	end
end

function t:update(dt)
	timer = timer + dt
	if timer > 0.5 then
		timer = timer - 0.5
		self.draw_cursor = not self.draw_cursor
	end
end

function t:textinput(c)
	if not valid_chars[c] then
		return
	end
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
			if level_io:create_level(self.text) then
				game.set_level(self.text)
				file_browser:update_contents()
				file_browser.enabled = false
				level.generate_list()
			end
			game:set_state("editor")
		elseif self.mode == "directory" then
			file_browser:mkdir(self.text)
			file_browser:update_contents()
			game:set_state("editor")
		end
	elseif key == "escape" then
		game:set_state("editor")
	end
	return true
end

return t
