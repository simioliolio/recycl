GridViewModel = require 'recycl/gridviewmodel'
Sequencer = require 'recycl/sequencer'
require 'recycl/grideventtype'

GridModel = {}

function GridModel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.view = GridViewModel:new()
    self.transport_lambda = function(play) end  -- replace externally
    self.update_lambda = function() end         -- replace externally
    self.number_of_parts = 8
    self.sequence_length = 8
    self.sequencer = Sequencer:new()
    self.seq_buttons_held = 0
    self.part_being_edited = nil
    self.on_presses_for_edited_part = {} -- TODO: rename
    return o
end

function GridModel:clock_tick()
end

-- actions

function GridModel:play()
    self.transport_lambda(true)
    self.view.playing = true
    self.update_lambda()
end

function GridModel:stop()
    self.transport_lambda(false)
    self.view.playing = false
    self.update_lambda()
end

-- Based on sequencer interaction, add data into sequencer
-- Data:
    -- event_type: ["start"]/["tail"]
    -- part: [part number]
    -- if event_type == "start":
        -- length: [length of event in steps]
function GridModel:sequencer_interaction(x, y, z)
    local part = y + (self.view.first_visible_part - 1)
    if z == 1 then
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
                print("no existing event")
                self:add_start_event(sequenced_step, part)
            else
                if #existing_at_step ~= 1 then print("!! duplicate events argh only working with mono sequence !!") return end
                local existing_event = existing_at_step[1]
                print("event_type: " .. existing_event.event_type)
                if existing_event.event_type == GridEventType.START then

                    if part ~= existing_event.part then
                        -- Part is different. Kill the existing and replace.
                        self:clear_note(sequenced_step, existing_event.part)
                        self:add_start_event(sequenced_step, part)
                    else
                        -- Could be trying to remove event, or trying to add tail to event
                        -- Save for later, but only for the part first recorded
                        -- FIXME surely there is a better way to do this. Only add to table if part is the same as existing value's part
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
                    -- Is only a tail...
                    print("its only a tail")
                    self:clear_note(sequenced_step, part)
                    self:add_start_event(sequenced_step, part)
                else
                    print("UNKNOWN, " .. existing_event.event_type)
                end
            end
        end
    else
        self.seq_buttons_held = self.seq_buttons_held - 1
        if self.seq_buttons_held == 0 then
            if #self.on_presses_for_edited_part == 1 then
                -- Only one press when press on existing event, so remove
                local clear_press = self.on_presses_for_edited_part[1]
                self.sequencer:clear(clear_press.step)
            elseif #self.on_presses_for_edited_part == 2 then
                -- A second on press tried to extend the length
                local start_press = self.on_presses_for_edited_part[1]
                local extend_press = self.on_presses_for_edited_part[2]
                if start_press.step < extend_press.step then
                    local number_of_tails = extend_press.step - start_press.step
                    local part_for_tail = start_press.part
                    local tail_start = start_press.step + 1
                    for i = tail_start, start_press.step + number_of_tails do
                        print("adding tail events! " .. i)
                        self:add_tail_event(i, part_for_tail)
                    end
                end
            end
            self.on_presses_for_edited_part = {}
        end
    end
end

function GridModel:clear_note(step, part)
    self.sequencer:clear(step)
    for i = step + 1, step + 16 do
        local future_events = self.sequencer.sequence[i]
        if not future_events then return end
        local future_event = future_events[1]
        if future_event.part ~= part then return end
        if future_event.event_type == GridEventType.TAIL then
            self.sequencer:clear(i)
        end
    end
end

function GridModel:add_start_event(step, part)
    local event = {}
    event.event_type = GridEventType.START
    event.part = part
    self.sequencer:add(step, event)
end

function GridModel:add_tail_event(step, part)
    local event = {}
    event.event_type = GridEventType.TAIL
    event.part = part
    self.sequencer:add(step, event)
end

-- Convert raw sequence data to view sequence data
function GridModel:update_view_seq()
    self.view:init_sequence_data() -- init to blank 16x7 'matrix'
    for sequenced_step = self.view.first_visible_step, self.view.max_sequence_length do
        local events_for_step = self.sequencer.sequence[sequenced_step]
        if events_for_step == nil then
            goto continue
        end
        for _, event in ipairs(events_for_step) do
            local sequenced_part = event[1]
            local visible_part = sequenced_part - (self.view.first_visible_part - 1)
            local visible_step = sequenced_step - (self.view.first_visible_step - 1)
            local length = event[2]
            self.view.sequence_data[visible_step][visible_part] = length
        end
        ::continue::
    end
    self.update_lambda()
end

-- /actions

return GridModel