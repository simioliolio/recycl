require('table')

-- Sequencer of arbitrary data
Sequencer = {
    current_step = nil,
    sequence = {}, -- table of tables
    did_advance = function(current_step) end,
    sequence_length = 0, -- Dev note: Use ParamID.sequence_length param
    event_subscribers = {},
    change_subscribers = {}
}

function Sequencer:reset()
    self.current_step = nil
    self.sequence = {}
    self.event_subscribers = {}
    self.change_subscribers = {}
    self.sequence_length = 0
end

function Sequencer:advance()
    -- advance
    if self.current_step == nil then
        self.current_step = 1
    else
        self.current_step = self.current_step + 1
    end
    -- wrap
    if self.current_step > self.sequence_length then self.current_step = 1 end
    -- trigger any new events
    local events_at_current_step = self.sequence[self.current_step]
    if events_at_current_step ~= nil and #events_at_current_step > 0 then
        for i, event in ipairs(events_at_current_step) do
            self:send_advance_event_to_subscribers(self.current_step, event)
        end
    else
        self:send_advance_event_to_subscribers(self.current_step, nil)
    end
end

function Sequencer:add(step, data_table)
    local step_data = self.sequence[step] or {}
    table.insert(step_data, data_table)
    self.sequence[step] = step_data
    self:send_change_event_to_subscribers(self.sequence)
end

function Sequencer:clear(step)
    self.sequence[step] = nil
    self:send_change_event_to_subscribers(self.sequence)
end

-- `lambda` called when sequencer has event and next position in time
-- Note: lambda should take two parameters, current_step (int) and event (table))
function Sequencer:subscribe_to_event(lambda)
    table.insert(self.event_subscribers, lambda)
end

function Sequencer:send_advance_event_to_subscribers(current_step, event)
    for i, lambda in ipairs(self.event_subscribers) do
        lambda(current_step, event)
    end
end

-- `lambda` called when sequence data is added / removed
-- Note: lambda takes one parameter, sequence (table of tables)
function Sequencer:subscribe_to_change(lambda)
    table.insert(self.change_subscribers, lambda)
end

function Sequencer:send_change_event_to_subscribers(sequence)
    for i, lambda in ipairs(self.change_subscribers) do
        lambda(self.sequence)
    end
end

return Sequencer
