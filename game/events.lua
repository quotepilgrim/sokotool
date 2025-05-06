local t = {}
t.queue = {}

function t:send(event)
	table.insert(self.queue, event)
end

function t:read(event)
	for i, e in ipairs(self.queue) do
		if e == event then
			return table.remove(self.queue, i)
		end
	end
end

return t
