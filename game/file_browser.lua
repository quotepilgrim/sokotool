local t = {}
local lfs = require("lfs")
local events = require("events")
local utf8 = require("utf8")
local level_io = require("level_io")
local msg = require("message")
local root = love.filesystem.getSourceBaseDirectory()
local inc = 2 + love.graphics.getFont():getHeight()
local height = 320
local max_visible = math.floor(height / inc)
local anchor_line = 10
local scroll_start, scroll_end
local roam_free = false

t.enabled = false
t.contents = {}
t.active = 1
t.x, t.y = 4, 0

for _, v in ipairs(arg) do
	if v == "--danger-zone" then
		roam_free = true
	end
end

local function compare(a, b)
	local split_ext = "^([^%.]*)%.?(.-)$"
	local split_num = "^(.-)(%d*)$"
	local base_a, base_b, num_a, num_b, ext_a, ext_b

	base_a, ext_a = a:match(split_ext)
	base_b, ext_b = b:match(split_ext)
	base_a, num_a = base_a:match(split_num)
	base_b, num_b = base_b:match(split_num)

	if base_a ~= base_b then
		return base_a < base_b
	end

	if num_a ~= num_b and num_a ~= "" and num_b ~= "" then
		local na, nb = tonumber(num_a), tonumber(num_b)
		if na == nb then
			return #num_a < #num_b
		else
			return na < nb
		end
	end

	if ext_a ~= ext_b then
		return ext_a < ext_b
	end
end

function t:update_contents()
	self.contents = {}
	self.active = 1
	local files = {}
	for i in lfs.dir(".") do
		if i ~= "." and i ~= ".." and utf8.len(i) then
			local attr = lfs.attributes(i)
			if attr and attr.mode == "directory" then
				table.insert(self.contents, i .. "/")
			else
				table.insert(files, i)
			end
		end
	end

	table.sort(self.contents, compare)

	if not roam_free and self:current() == root then
		return
	end

	table.insert(self.contents, 1, "..")
	table.sort(files, compare)

	for _, i in ipairs(files) do
		table.insert(self.contents, i)
	end
end

function t:get_active()
	return self.contents[self.active]
end

function t:current()
	return lfs.currentdir():gsub("\\", "/")
end

function t:chdir(dir)
	local full_path = lfs.currentdir() .. "/" .. dir:match("([^/]+)")
	local attr = lfs.attributes(full_path)
	if attr and attr.mode ~= "directory" then
		return false
	end
	local _, err = lfs.chdir(dir)
	if err then
		print(err)
		return false
	end
	t:update_contents()
	return true
end

function t:mkdir(dir)
	local result, err = lfs.mkdir(dir)
	if err then
		print(err)
	end
	self:update_contents()
	return result
end

function t:rmdir(dir)
	if dir == ".." then
		msg:show("can't delete parent directory.", "error")
		return
	end
	if not self:chdir(dir) then
		msg:show("not a valid directory.", "error")
		return
	end
	for _, i in ipairs(self.contents) do
		local file = level_io.load(i)
		if file.grid or file.levels then
			os.remove(i)
		end
	end
	self:chdir("..")
	local _, err = lfs.rmdir(dir)
	if err then
		msg:show("could not delete directory.", "error")
	end
	self:update_contents()
end

function t:update()
	if not self.enabled then
		return false
	end
	scroll_start = math.max(1, self.active - anchor_line)
	scroll_end = scroll_start + max_visible

	if scroll_end > #self.contents then
		scroll_start = math.max(1, #self.contents - max_visible)
		scroll_end = #self.contents
	end
	return true
end

function t:draw()
	love.graphics.setColor(0, 0, 0, 0.6)
	love.graphics.rectangle("fill", 0, 0, 640, 640)
	love.graphics.setColor(1, 1, 1, 1)

	local x, y = self.x, self.y

	for i = scroll_start, scroll_end do
		if i == self.active then
			love.graphics.rectangle("fill", 0, y, 640, inc)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.print(self.contents[i] or "", x, y)
			love.graphics.setColor(1, 1, 1, 1)
		else
			love.graphics.print(self.contents[i] or "", x, y)
		end
		y = y + inc
	end
end

function t:keypressed(key)
	if key == "s" or key == "down" then
		self.active = math.min(self.active + 1, #self.contents)
	elseif key == "w" or key == "up" then
		self.active = math.max(self.active - 1, 1)
	elseif key == "return" or key == "space" then
		if not self:chdir(self:get_active()) then
			events:send("level_select")
			self.enabled = false
		end
	elseif key == "b" or key == "tab" or key == "backspace" then
		self.enabled = false
	else
		return false
	end
	return true
end

return t
