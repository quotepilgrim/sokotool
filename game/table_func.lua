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
	for k, v in pairs(t) do
		local formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			table.dump(v, indent + 1)
		else
			print(formatting .. tostring(v))
		end
	end
end
