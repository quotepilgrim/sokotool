local t = {}

t.opacity = 0

t.inc = {
	["in"] = -1,
	["out"] = 1,
}
local inc = 0

function t:start(mode, speed, func)
	inc = (self.inc[mode] and self.inc[mode] * speed) or 1
	if mode == "in" then
		self.opacity = 1
	else
		self.opacity = 0
	end
	self.mode = mode
	self.callback = func
    self.done = false
end

function t:complete()
	self.inc = 0
end

function t:update(dt)
	if self.done then
		return
	end
	self.opacity = self.opacity + dt * inc
	if self.mode == "in" and self.opacity < 0 then
		self.opacity = 0
		self.done = true
	elseif self.mode == "out" and self.opacity > 1 then
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
