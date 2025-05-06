local t = {}
t.queue = {}

local function copy_grid(grid, pos)
	local new_grid = {}
	for i, row in ipairs(grid) do
		new_grid[i] = {}
		for _, col in ipairs(row) do
			table.insert(new_grid[i], col)
		end
	end
	new_grid.playerx = pos.x
	new_grid.playery = pos.y
	return new_grid
end

function t:push(grid, pos)
	return table.insert(self.queue, copy_grid(grid, pos))
end

function t:pop()
	return table.remove(self.queue)
end

function t:clear()
	self.queue = {}
end

function t:get(n)
	return self.queue[n]
end

return t
