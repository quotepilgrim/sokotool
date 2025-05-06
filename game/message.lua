local t = {}

t.text = ""
t.timer = 0
t.color = { 1, 1, 1, 1 }
t.x, t.y = 8, 620

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
	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle("fill", 0, self.y-2, 640, 22)
	love.graphics.setColor(unpack(self.color))
	love.graphics.print(self.text, self.x, self.y)
	love.graphics.setColor(1, 1, 1, 1)
end

function t:show(msg, type)
	local prefix
	if type == "error" then
		prefix = "ERROR: "
		self.color = { 1, 0, 0, 1 }
	else
		prefix = ""
		self.color = { 0.5, 0.5, 1, 1 }
	end
	self.timer = 2
	self.text = prefix .. msg
end

return t
