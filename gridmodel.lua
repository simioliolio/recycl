GridViewModel = require 'recycl/gridviewmodel'
Sequencer = require 'recycl/sequencer'
require 'recycl/grideventtype'

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
    self.seq_buttons_held = 0
    self.current_held_interations = {{}} -- {x, y, mode}
    self.part_being_edited = nil
    self.on_presses_for_edited_part = {} -- TODO: rename
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

-- TODO: make private
function GridModel:play()
    self.transport_lambda(true)
    self.view.playing = true
end

-- TODO: make private
function GridModel:stop()
    self.transport_lambda(false)
    self.view.playing = false
    self.sequencer.current_step = nil
    self.view:update_current_visible_step(nil)
end

-- TODO: make private
function GridModel:route(x, y, z, mode)
    -- Globals
    if x == 1 and y == 8 and z == 1 then self:stop() return
    elseif x == 2 and y == 8 and z == 1 then self:play() return
    end
    -- Per mode
    if mode == self.Modes.SEQUENCE then
        if y < 8 then self:sequencer_interaction(x, y, z) end
        return
    elseif mode == self.Modes.CLOCK_DIV then
        -- TODO: Handle clock div interaction
        return
    end
end

-- Based on sequencer interaction, add data into sequencer
-- Data:
    -- event_type: ["start"]/["tail"]
    -- part: [part number]
-- TODO: make private
function GridModel:sequencer_interaction(x, y, z)
    local part = y + (self.view.first_visible_part - 1)
    if z == 1 then

        -- On presses --

        local sequenced_step = x + (self.view.first_visible_step - 1)
        self.seq_buttons_held = self.seq_buttons_held + 1

        if #self.on_presses_for_edited_part > 0 then
            -- Focus mode
            local first = self.on_presses_for_edited_part[1]    -- TODO: shorten to one line?
            local focus_part = first.part                       --
            if part == focus_part then
                local on_press = {step=sequenced_step, part=part}
                table.insert(self.on_presses_for_edited_part, on_press)
            end
        else
            -- Normal mode
            local existing_at_step = self.sequencer.sequence[sequenced_step]
            if not existing_at_step then
                -- No existing event, add event
                self:clear_note(sequenced_step)
                self:add_start_event(sequenced_step, part)
            else
                if #existing_at_step ~= 1 then print("!! duplicate events argh only working with mono sequence !!") return end
                local existing_event = existing_at_step[1]
                if existing_event.event_type == GridEventType.START then

                    if part ~= existing_event.part then
                        -- Part is different. Kill the existing and replace.
                        self:clear_note(sequenced_step)
                        self:add_start_event(sequenced_step, part)
                    else
                        -- Could be trying to remove event, or trying to add tail to event
                        -- Save for later, but only for the part first recorded
                        -- FIXME: surely there is a better way to do this. Only add to table if part is the same as the part found in the table
                        local focus_part = part
                        if #self.on_presses_for_edited_part > 0 then
                            local first = self.on_presses_for_edited_part[1]
                            focus_part = first.part
                        end
                        if part == focus_part then
                            local on_press = {step=sequenced_step, part=part}
                            table.insert(self.on_presses_for_edited_part, on_press)
                        end
                    end
                elseif existing_event.event_type == GridEventType.TAIL then
                    self:clear_note(sequenced_step)
                    self:add_start_event(sequenced_step, part)
                end
            end
        end
    else

        -- Off presses --

        self.seq_buttons_held = self.seq_buttons_held - 1
        if self.seq_buttons_held == 0 then
            if #self.on_presses_for_edited_part == 1 then
                -- Only one press when press on existing event, so remove
                local clear_press = self.on_presses_for_edited_part[1]
                self:clear_note(clear_press.step)
            elseif #self.on_presses_for_edited_part == 2 then
                -- A second on press tried to extend the length
                local start_press = self.on_presses_for_edited_part[1]
                local extend_press = self.on_presses_for_edited_part[2]
                if start_press.step < extend_press.step then
                    local number_of_tails = extend_press.step - start_press.step
                    local part_for_tail = start_press.part
                    local tail_start = start_press.step + 1
                    for i = tail_start, start_press.step + number_of_tails do
                        self:clear_note(i)
                        self:add_tail_event(i, part_for_tail)
                    end
                end
            end
            self.on_presses_for_edited_part = {}
        end
    end
    self:update_view_seq()
end

-- Clears a note and tail from a specific step
-- TODO: Make private
function GridModel:clear_note(step)
    local existing = self.sequencer.sequence[step]
    if not existing then return end
    if #existing == 0 then return end
    local first_event = existing[1]
    local part = first_event.part
    self.sequencer:clear(step)
    -- After clearing at the step specified, clear any trailing tail for the same part
    for i = step + 1, step + 16 do -- TODO: Does not need to be 16
        local future_events = self.sequencer.sequence[i]
        if not future_events then return end
        local future_event = future_events[1]
        if future_event.part ~= part then return end
        if future_event.event_type == GridEventType.TAIL then
            self.sequencer:clear(i)
        end
    end
end

-- TODO: Make private
function GridModel:add_start_event(step, part)
    local event = {}
    event.event_type = GridEventType.START
    event.part = part
    self.sequencer:add(step, event)
end

-- TODO: Make private
function GridModel:add_tail_event(step, part)
    local event = {}
    event.event_type = GridEventType.TAIL
    event.part = part
    self.sequencer:add(step, event)
end

-- Convert raw sequence data to view sequence data
-- TODO: Make private
function GridModel:update_view_seq()
    self.view:init_sequence_data() -- init to blank 16x7 'matrix'
    for sequenced_step = self.view.first_visible_step, self.view.max_visible_sequence_length do
        local events_for_step = self.sequencer.sequence[sequenced_step]
        if events_for_step == nil then
            goto continue
        end
        for _, event in ipairs(events_for_step) do
            local sequenced_part = event.part
            local visible_part = sequenced_part - (self.view.first_visible_part - 1)
            local visible_step = sequenced_step - (self.view.first_visible_step - 1)
            self.view.sequence_data[visible_step][visible_part] = event.event_type
        end
        ::continue::
    end
end

return GridModel