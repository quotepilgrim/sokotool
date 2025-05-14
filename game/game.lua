local t = {}

t.mousex, t.mousey = 0, 0
t.mouseactive = false

t.states = {
    main = {},
    editor = {},
    menu = {},
    input = {},
}

t.dirs = {
    up = { 0, -1 },
    down = { 0, 1 },
    left = { -1, 0 },
    right = { 1, 0 },
}

t.state = "main"
t.prev_state = "main"
t.level = {}

function t:set_state(new_state)
    if new_state == self.state then
        return
    end
    self.prev_state = self.state
    self.state = new_state
    self.player.sprite = self.player.sprites[self.state] or self.player.sprite
end

return t
