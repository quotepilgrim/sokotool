function table.slice(t, first, last)
	local slice = {}
	for i = first or 1, last or #t do
		slice[#slice + 1] = t[i]
	end
	return slice
end

function table.dump(t, indent)
	if not indent then
		indent = 0
	end
	local keys = {}
	for k, _ in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in pairs(keys) do
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(t[k]) == "table" then
			print(formatting)
			table.dump(t[k], indent + 1)
		else
			print(formatting .. tostring(t[k]))
		end
	end
end

function table.index(t)
	local indices = {}
	for i, v in ipairs(t) do
		indices[v] = i
	end
	return indices
end
