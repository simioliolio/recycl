table = require 'table'

local GRID_SIZE_X = 16
local GRID_SIZE_Y = 8

local clean_grid_matrix = function(z)
    local grid_table = {}
    for i=1,GRID_SIZE_X do
        grid_table[i] = {}
        for j=1,GRID_SIZE_Y do
            grid_table[i][j] = z
        end
    end
    return grid_table
end

OnScreenGrid = {
    -- x, y, z
    leds = clean_grid_matrix(0),
    dirty_screen = true,
    momentary_presses = clean_grid_matrix(0),
    toggle_presses = clean_grid_matrix(0),
    cursor_position = {x = 1, y = 1},
    key_subscriptions = {}
}

-- private

local key_received = function(self, x, y, z)
    for _, key_function in ipairs(self.key_subscriptions) do
        key_function(x, y, z)
    end
end

-- public

function OnScreenGrid:init()
    self.connected_grid = grid.connect()
    self.connected_grid.key = function(x, y, z)
        print("grid sending "..x..y..z)
        key_received(self, x, y, z)
    end
end

local clear_momentary_presses = function(self)
    for col=1, GRID_SIZE_X do
        for row=1, GRID_SIZE_Y do
            local press = self.momentary_presses[col][row]
            if press == 1 then
                key_received(self, col, row, 0)
            end
        end
    end
    self.momentary_presses = clean_grid_matrix(0)
end

function OnScreenGrid:key(n,z)
    -- TODO: Generate presses
    if n == 2 then
        -- Momentary press
        if z == 1 then
            local cur = self.cursor_position
            key_received(self, cur.x, cur.y, 1)
            self.momentary_presses[cur.x][cur.y] = 1
        else
            clear_momentary_presses(self)
        end
        self.dirty_screen = true
    elseif n == 3 then
        -- Toggle press
        if z == 1 then
            local cur = self.cursor_position
            -- flip
            local state = self.toggle_presses[cur.x][cur.y]
            local flipped = 1 - state
            self.toggle_presses[cur.x][cur.y] = flipped
            key_received(self, cur.x, cur.y, flipped)
            self.dirty_screen = true
        end
    end
end

function OnScreenGrid:enc(n,d)
    clear_momentary_presses(self)
    if n == 2 then
        self.cursor_position.x = self.cursor_position.x + d
        if self.cursor_position.x > 16 then
            self.cursor_position.x = 16
        elseif self.cursor_position.x < 1 then
            self.cursor_position.x = 1
        end
    elseif n == 3 then
        self.cursor_position.y = self.cursor_position.y + d
        if self.cursor_position.y > 8 then
            self.cursor_position.y = 8
        elseif self.cursor_position.y < 1 then
            self.cursor_position.y = 1
        end
    end
    self.dirty_screen = true
end

-- key_function example:
-- function(x, y, z) handle_keys(x, y, z) end
function OnScreenGrid:subscribe_to_keys(key_function)
    table.insert(self.key_subscriptions, key_function)
end

function OnScreenGrid:display_render()
    screen.clear()
    screen.level(0)
    screen.rect(1,1,128,64)
    screen.fill()
    for col=1, GRID_SIZE_X do
        for row=1, GRID_SIZE_Y do
            -- led
            local led = self.leds[col][row]
            if led ~= 0 then
                screen.level(led)
                screen.rect(col*8-7,row*8-8+1,6,6)
                screen.fill()
            end
            -- 'push' dot
            if led > 0 then
                screen.level(0) -- Black push dot
            else
                screen.level(15) -- Yellow push dot
            end
            local toggle_press = self.toggle_presses[col][row]
            local momentary_press = self.momentary_presses[col][row]
            if toggle_press ~= 0 or momentary_press ~= 0 then
                screen.circle(col*8-7+3,row*8-8+1+3,2,2)
                screen.fill()
            end
        end
    end
    screen.level(15)
    screen.rect(self.cursor_position.x*8-7,self.cursor_position.y*8-8+1,7,7)
    screen.stroke()
    -- TODO: Comment out verbosity
    screen.aa(0)
    screen.font_size(8)
    screen.font_face(0)
    screen.move(110, 8)
    screen.text("("..self.cursor_position.x..","..self.cursor_position.y..")")
    screen.update()
    self.dirty_screen = false
end

-- public grid overrides

function OnScreenGrid:led(x, y, z)
    self.leds[x][y] = z
    self.connected_grid:led(x, y, z)
    self.dirty_screen = true
end

function OnScreenGrid:all(z)
    self.leds = clean_grid_matrix(z)
    self.connected_grid:all(z)
    self.dirty_screen = true
end

function OnScreenGrid:refresh()
    self.connected_grid:refresh()
    self.dirty_screen = true
end


return OnScreenGrid
