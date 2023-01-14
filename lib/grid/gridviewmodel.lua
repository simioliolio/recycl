GridViewModel = {}

-- View model used to set grid leds
function GridViewModel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.playing = false
    self.clock_div_set_enabled = false
    self.clock_div = 1 -- (1...7)
    self.mlr_goto_set_enabled = false
    self.sequence_length_set_enabled = false
    self.first_visible_step = 1     -- changes with horizonal scroll
    self.first_visible_part = 1     -- changes with vertical scroll
    self.max_visible_sequence_length = 16 -- grid width typically 16
    self.max_parts = 7
    self.current_visible_step = nil

    -- table of steps. a step is table of lengths for each part in that step.
    -- ie, {{0, 2, 0, 0}, {1, 0, 0, 0}}: two steps, four parts, data is length
    self.sequence_data = {}
    self:init_sequence_data() -- 16x7 matrix
    return o
end

function GridViewModel:init_sequence_data()
    local seq_data = {}
    for i = 1, self.max_visible_sequence_length do
        local part_data = {}
        for i = 1, self.max_parts do
            table.insert(part_data, 0)
        end
        table.insert(seq_data, part_data)
    end
    self.sequence_data = seq_data
end

-- Takes current position of sequencer
function GridViewModel:update_current_visible_step(current_step)
    if not current_step then
        self.current_visible_step = nil
    else
        if current_step < self.first_visible_step then
            -- before first visible step
            self.current_visible_step = nil
            return
        end
        if current_step > self.first_visible_step + self.max_visible_sequence_length - 1 then
            -- after last visible step
            self.current_visible_step = nil
            return
        end
        self.current_visible_step = current_step - (self.first_visible_step - 1)
    end

end

return GridViewModel