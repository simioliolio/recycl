GridViewModel = {}

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
    self.max_sequence_length = 16
    self.max_parts = 7

    -- table of steps. a step is table of lengths for each part in that step.
    -- ie, {{0, 2, 0, 0}, {1, 0, 0, 0}}: two steps, four parts, data is length
    self.sequence_data = {}
    self:init_sequence_data() -- 16x7 matrix
    return o
end

function GridViewModel:init_sequence_data()
    local seq_data = {}
    for i = 1, self.max_sequence_length do
        local part_data = {}
        for i = 1, self.max_parts do
            table.insert(part_data, 0)
        end
        table.insert(seq_data, part_data)
    end
    self.sequence_data = seq_data
end

return GridViewModel