require('table')

Sequencer = {
    current_step = nil,
    sequence = {}, -- table of tables
    did_advance = function(current_step) end,
    sequence_length = 0, -- Dev note: Use ParamID.sequence_length param
    event_subscribers = {},
    advance_subscribers = {}
}

function Sequencer:reset()
    self.current_step = nil
    self.sequence = {}
    self.event_subscribers = {}
    self.advance_subscribers = {}
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
            self:send_event_to_subscribers(self.current_step, event)
        end
    else
        self:send_event_to_subscribers(self.current_step, nil)
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

-- Lambda must take two parameters, current_step (int) and event (table)
function Sequencer:subscribe_to_event(lambda)
    table.insert(self.event_subscribers, lambda)
end

function Sequencer:send_event_to_subscribers(current_step, event)
    for i, lambda in ipairs(self.event_subscribers) do
        lambda(current_step, event)
    end
end

return Sequencer
