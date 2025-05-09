local t = {}
local font

t.text = ""
t.timer = 0
t.color = { 1, 1, 1, 1 }
t.x, t.y = 0, 0
t.rect = { x = 0, y = 0, w = 0, h = 0 }

function t.load()
	font = love.graphics.getFont()
end

function t:update(dt)
	if self.timer > 0 then
		self.timer = self.timer - dt
	elseif self.timer < 0 then
		self.timer = 0
		self.text = ""
	end
end

function t:draw()
	if self.text == "" then
		return
	end
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", self.rect.x, self.rect.y, self.rect.w, self.rect.h)
	love.graphics.setColor(unpack(self.color))
	love.graphics.print(self.text, self.x, self.y)
	love.graphics.setColor(1, 1, 1, 1)
end

function t:show(msg, type)
	local prefix = ""
	local width = font:getWidth(msg)
	self.x, self.y = 4, 620
	if type == "error" then
		prefix = "ERROR: "
		self.color = { 1, 0, 0, 1 }
	elseif type == "title" then
		self.x = 320 - width / 2
		self.y = 2
		self.color = { 1, 1, 0.5, 1 }
	else
		self.color = { 0.5, 0.5, 1, 1 }
	end
	self.rect.x = self.x - 4
	self.rect.y = self.y - 2
	self.rect.w = width + 8
	self.rect.h = font:getHeight() + 4
	self.timer = 2
	self.text = prefix .. msg
end

return t
