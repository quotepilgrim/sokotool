local t = {}
local lfs = require("lfs")
local msg = require("message")

function t.load(filename)
	local level = {}
	local section, new_section, flat
	local separator = "|"
	local split_pattern = "([^" .. separator .. "]+)"
	local file = io.open(filename, "r")

	if not file then
		return
	end

	local function strip(str)
		return str and str:match("^%s*(.-)%s*$") or ""
	end

	local function process_line(line)
		local key, value = line:match("^(.+):(.*)$")
		if key and value == "" then
			section = key
			level[section] = {}
			new_section = true
			flat = false
			return true
		elseif key then
			section = nil
			if not value:find(separator) then
				level[key] = tonumber(value) or strip(value)
				return true
			end
			level[key] = {}
			for item in value:gmatch(split_pattern) do
				table.insert(level[key], tonumber(item) or strip(item))
			end
		end
		if section then
			if new_section then
				if not line:find(separator) then
					flat = true
				end
				new_section = false
			end
			if flat then
				if line:find(separator) then
					return false
				end
				table.insert(level[section], tonumber(line) or line)
				return true
			end
			if not line:find(separator) then
				return false
			end
			local row = {}
			for item in line:gmatch(split_pattern) do
				table.insert(row, tonumber(item) or strip(item))
			end
			table.insert(level[section], row)
		end
		return true
	end

	for line in file:lines() do
		line = strip(line)
		if line ~= "" then
			if not process_line(line) then
				return
			end
		end
	end
	file:close()
	return level
end

function t.save(level, filename)
	local file = io.open(filename, "w+")
	if not file then
		return false
	end
	local keys = {}
	for k, _ in pairs(level) do
		table.insert(keys, k)
	end
	table.sort(keys)
	for _, k in ipairs(keys) do
		if type(level[k][1]) ~= "table" and type(level[k]) == "table" then
			file:write(k .. ": " .. table.concat(level[k], "|") .. "\n")
		elseif type(level[k]) == "table" then
			file:write(k .. ":\n")
			for _, item in ipairs(level[k]) do
				if #item == 1 and type(item) == "table" then
					file:write(item[1] .. "|\n")
				elseif type(item) == "table" then
					file:write(table.concat(item, "|") .. "\n")
				else
					file:write(item .. "\n")
				end
			end
		else
			file:write(k .. ": " .. level[k] .. "\n")
		end
	end
	file:close()
	return true
end

function t:create_level(filename)
	if lfs.attributes(filename) then
		msg:show("file exists.", "error")
		return false
	end
	local rows, cols = 20, 20
	local level = {
		grid = {},
		name = filename:match("([^%.]+)"),
		playerstart = "4|4",
	}
	for i = 1, rows do
		level.grid[i] = {}
		for j = 1, cols do
			local tile = 0
			if ((i == 2 or i == 6) and j >= 2 and j <= 6) or ((j == 2 or j == 6) and i >= 2 and i <= 6) then
				tile = 2
			elseif i > 2 and i < 6 and j > 2 and j < 6 then
				tile = 1
			end
			level.grid[i][j] = tile
		end
	end
	return self.save(level, filename)
end

return t
