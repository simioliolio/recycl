GridViewModel = require 'recycl/gridviewmodel'
Sequencer = require 'recycl/sequencer'
require 'recycl/grideventtype'
GridSequencerModel = require 'recycl/gridsequencermodel'

GridModel = {}

function GridModel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.view = GridViewModel:new()
    self.transport_lambda = function(play) end      -- replace externally
    self.update_lambda = function() print("error, no update function set") end              -- TODO: Pass on init?
    self.set_clock_div = function(clock_div) print("error, no clock div function set") end  --
    self.number_of_parts = 8
    self.sequence_length = 8
    self.sequencer = Sequencer:new()
    self.sequencer_model = GridSequencerModel:new( {
        sequencer = self.sequencer,
        view = self.view
    })
    self.current_held_interations = {{}} -- {x, y, mode}
    self.clock_div = 4 -- TODO: Could move to view model
    self.set_clock_div(self.clock_div)
    self.Modes = {
        SEQUENCE = "sequence",
        CLOCK_DIV = "clock_div",
    }
    self.mode = self.Modes.SEQUENCE
    return o
end

function GridModel:clock_tick()
    -- Update callback to ensure an externally-set `update_lambda` is used in `did_advance()`
    -- FIXME: Remove if `update_lambda` is passed on init
    self.sequencer.did_advance = function(current_step) self:did_advance(current_step) end
    self.sequencer:advance()
end

function GridModel:did_advance(current_step)
    self.view:update_current_visible_step(current_step)
    self.update_lambda()
end

function GridModel:interaction(x, y, z)
    -- Determine if mode has changed
    if y == 8 then
        if z == 1 then
            if x == 3 then
                self.mode = self.Modes.CLOCK_DIV
            end
        else
            -- All off-presses return to sequence mode.
            -- Dangling on presses for row 8 will be ignored
            self.mode = self.Modes.SEQUENCE
        end
    end
    -- Route on presses
    if z == 1 then
        -- TODO: Way of doing this in one step?
        local held = {}
        held[y] = self.mode
        self.current_held_interations[x] = held
        self:route(x, y, 1, self.mode)
    else
        -- Match off presses to mode of previous on press, and flush
        local mode_of_previous_on_press = self.current_held_interations[x][y]
        if mode_of_previous_on_press then
            self:route(x, y, 0, mode_of_previous_on_press)
            self.current_held_interations[x][y] = nil
        else
            print("non-fatal: no on press recorded for off press " .. x .. y .. z)
        end
    end
    self.update_lambda()
end

function GridModel:play()
    self.transport_lambda(true)
    self.view.playing = true
end

function GridModel:stop()
    self.transport_lambda(false)
    self.view.playing = false
    self.sequencer.current_step = nil
    self.view:update_current_visible_step(nil)
end

function GridModel:route(x, y, z, mode)
    -- Globals
    if x == 1 and y == 8 and z == 1 then self:stop() return
    elseif x == 2 and y == 8 and z == 1 then self:play() return
    end
    -- Per mode
    if mode == self.Modes.SEQUENCE then
        if y < 8 then self.sequencer_model:sequencer_interaction(x, y, z) end
        return
    elseif mode == self.Modes.CLOCK_DIV then
        -- TODO: Handle clock div interaction
        return
    end
end

return GridModel