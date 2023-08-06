Sequencer = include "recycl/lib/common/sequencer"
ParamID = include 'recycl/lib/common/paramid'

GridSequencerModel = {}

function GridSequencerModel:new(o)
    o = o or {
        view = GridViewModel:new()
    }
    setmetatable(o, self)
    self.__index = self
    self.seq_buttons_held = 0
    self.on_presses_for_edited_part = {} -- TODO: rename
    return o
end

-- Based on sequencer interaction, add data into sequencer
-- Data:
    -- event_type: ["start"]/["tail"]
    -- part: [part number]
function GridSequencerModel:sequencer_interaction(x, y, z)
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
            local existing_at_step = Sequencer.sequence[sequenced_step]
            if not existing_at_step then
                -- No existing event, add event
                self:clear_note(sequenced_step)
                self:add_start_event(sequenced_step, part)
            else
                if #existing_at_step ~= 1 then print("!! duplicate events found at a single step when trying to work with mono sequence !!") return end
                local existing_event = existing_at_step[1]
                if existing_event.event_type == SequenceEventType.START then

                    if part ~= existing_event.part then
                        -- Part is different. Kill the existing and replace.
                        self:clear_note(sequenced_step)
                        self:add_start_event(sequenced_step, part)
                    else
                        local on_press = nil
                        if #self.on_presses_for_edited_part == 0 then
                            on_press = {step=sequenced_step, part=part}
                        else
                            if self.on_presses_for_edited_part[1].part == part then
                                on_press = {step=sequenced_step, part=part}
                            end
                        end
                        if on_press then
                            table.insert(self.on_presses_for_edited_part, on_press)
                        end
                    end
                elseif existing_event.event_type == SequenceEventType.TAIL then
                    self:clear_note(sequenced_step)
                    self:add_start_event(sequenced_step, part)
                end
            end
        end
    end

    if z == 0 then
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
function GridSequencerModel:clear_note(step)
    local existing = Sequencer.sequence[step]
    if not existing then return end
    if #existing == 0 then return end
    local first_event = existing[1]
    local part = first_event.part
    Sequencer:clear(step)
    -- After clearing at the step specified, clear any trailing tail for the same part
    for i = step + 1, step + 16 do -- TODO: Does not need to be 16
        local future_events = Sequencer.sequence[i]
        if not future_events then return end
        local future_event = future_events[1]
        if future_event.part ~= part then return end
        if future_event.event_type == SequenceEventType.TAIL then
            Sequencer:clear(i)
        end
    end
end

function GridSequencerModel:add_start_event(step, part)
    local event = {}
    event.event_type = SequenceEventType.START
    event.part = part
    Sequencer:add(step, event)
    self:accomodate_step(step)
end

function GridSequencerModel:add_tail_event(step, part)
    local event = {}
    event.event_type = SequenceEventType.TAIL
    event.part = part
    Sequencer:add(step, event)
    self:accomodate_step(step)
end

function GridSequencerModel:accomodate_step(step)
    -- grow the sequence length to accommodate
    local sequence_length = params:get(ParamID.seq_length)
    if step > sequence_length then
        params:set(ParamID.seq_length, step, false)
    end
end

-- Convert raw sequence data to view sequence data
function GridSequencerModel:update_view_seq()
    self.view:init_sequence_data() -- init to blank 16x7 'matrix'
    for sequenced_step = self.view.first_visible_step, self.view.max_visible_sequence_length do
        local events_for_step = Sequencer.sequence[sequenced_step]
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

return GridSequencerModel