local t = {}

t.opacity = 0
t.inc = 0

t.modes = {
	["in"] = -1,
	["out"] = 1,
}

function t:start(mode, speed, callback)
	self.inc = (self.modes[mode] and self.modes[mode] * speed) or speed
	if mode == "in" then
		self.opacity = 1
	else
		self.opacity = 0
	end
	self.mode = mode
	self.callback = callback
	self.done = false
end

function t:update(dt)
	if self.done then
		return
	end
	self.opacity = self.opacity + dt * t.inc
	if self.opacity < 0 and self.mode == "in" then
		self.opacity = 0
		self.done = true
	elseif self.opacity > 1 and self.mode == "out" then
		self.opacity = 1
		self.done = true
	end
	if self.done and self.callback then
		self.callback()
	end
end

function t:draw()
	if self.opacity == 0 then
		return
	end
	love.graphics.setColor(0, 0, 0, self.opacity)
	love.graphics.rectangle("fill", 0, 0, 640, 640)
	love.graphics.setColor(1, 1, 1, 1)
end

return t
