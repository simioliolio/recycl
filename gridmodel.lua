GridViewModel = require 'recycl/gridviewmodel'
Sequencer = require 'recycl/sequencer'

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
    self.on_presses_for_edited_part = {}
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

function GridModel:sequencer_interaction(x, y, z)
    local part = y + (self.view.first_visible_part - 1)
    if z == 1 then
        local sequenced_step = x + (self.view.first_visible_step - 1)
        self.seq_buttons_held = self.seq_buttons_held + 1
        -- remove existing if exists
        local existing_at_step = self.sequencer.sequence[sequenced_step]
        if existing_at_step ~= nil then
            print("clearing for sequenced_step " .. sequenced_step)
            self.sequencer:clear(sequenced_step)
            return
        end
        -- capture part to focus if this is the first on press
        if self.seq_buttons_held == 1 then self.part_being_edited = part end
        if part ~= self.part_being_edited then
            print("part not being edited: " .. part)
            return -- part needs completing, ignore other part
        else
            print("adding to on_presses: " .. sequenced_step)
            table.insert(self.on_presses_for_edited_part, sequenced_step)
        end
    else
        self.seq_buttons_held = self.seq_buttons_held - 1
        if self.seq_buttons_held == 0 then
            -- flush accumilated on presses for edited part
            self.part_being_edited = nil
            if #self.on_presses_for_edited_part == 0 then
                return -- nothing to add
            end
            table.sort(self.on_presses_for_edited_part)
            local first_step = table.remove(self.on_presses_for_edited_part, 1)
            local new_data = {part, 1} -- part and length
            for i, subsequent_step in ipairs(self.on_presses_for_edited_part) do
                local length_to_add = subsequent_step - first_step
                local current_length = new_data[2]
                new_data[2] = current_length + length_to_add
            end
            -- clear any existing events that exists during the span of new data
            -- TODO: This does not account for long events before first_step
            for i = first_step, new_data[2] do
                self.sequencer:clear(i)
            end
            self.sequencer:add(first_step, new_data)
        end
    end

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