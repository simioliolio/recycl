require('table')

Sequencer = {}

function Sequencer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.current_step = nil
    self.sequence = {}
    self.event_callback = function(event_table) end
    return o
end

function Sequencer:advance()
    -- advance
    if self.current_step == nil then
        self.current_step = 1
    else
        self.current_step = self.current_step + 1
    end
    -- trigger any new events
    local events_at_current_step = self.sequence[self.current_step]
    if events_at_current_step ~= nil then
        for i, event in ipairs(events_at_current_step) do
            self.event_callback(event)
        end
    end
end

function Sequencer:add(step, data_table)
    local step_data = self.sequence[step] or {}
    table.insert(step_data, data_table)
    self.sequence[step] = step_data
end

function Sequencer:clear(step)
    self.sequence[step] = nil
end

return Sequencer
