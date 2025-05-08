local t = {}
t.queue = {}

local function copy_grid(grid, px, py)
	local new_grid = {}
	for i, row in ipairs(grid) do
		new_grid[i] = {}
		for _, col in ipairs(row) do
			table.insert(new_grid[i], col)
		end
	end
	new_grid.playerx = px
	new_grid.playery = py
	return new_grid
end

function t:push(grid, px, py)
	return table.insert(self.queue, copy_grid(grid, px, py))
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
