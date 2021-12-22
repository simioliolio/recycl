GridViewModel = {}

function GridViewModel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.sequence_data = {}
    self.playing = false
    self.clock_div_set_enabled = false
    self.clock_div = 1 -- (1...7)
    self.mlr_goto_set_enabled = false
    self.length_set_enabled = false
    return o
end

return GridViewModel