GridModel = include 'recycl/lib/grid/gridmodel'
GridViewModel = include 'recycl/lib/grid/gridviewmodel'
Sequencer = include 'recycl/lib/common/sequencer'
GridEventType = include 'recycl/lib/grid/grideventtype'

Grid = {}

function Grid:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    -- self.clock = o.clock
    -- if not self.clock then error("no clock passed to Grid") end
    self.clock_div = 2
    self.model = GridModel:new()
    clock.transport.start = function() self:start_clock() end
    clock.transport.stop = function() self:stop_clock() end
    self.model.transport_lambda = function(play)
        local t = clock.transport
        if play == true then t.start() else t.stop() end
    end
    self.model.update_lambda = function() self:redraw() end
    self.model.set_clock_div = function(model_clock_div)
        self.clock_div = model_clock_div
    end

    self.g = grid.connect()
    self.g.key = function(x, y, z)
        self:interaction(x, y, z)
    end

    self:redraw()
end

function Grid:start_clock()
    if self.clock_id then clock.cancel(self.clock_id) end
    self.clock_id = clock.run(function() self:clock_tick() end)
end

function Grid:stop_clock()
    if not self.clock_id then return end
    clock.cancel(self.clock_id)
end

function Grid:clock_tick()

    while true do
        clock.sync(1 / self.clock_div)
        self.model:clock_tick()
    end
end

function Grid:interaction(x, y, z)
    self.model:interaction(x, y, z)
end

function Grid:redraw()
    self.g:all(0)
    -- sequence
    for step_number, step in ipairs(self.model.view.sequence_data) do
        for part, event_type in ipairs(step) do
            if event_type == GridEventType.START then
                self.g:led(step_number, part, 15)
            elseif event_type == GridEventType.TAIL then
                self.g:led(step_number, part, 10)
            end
        end
    end
    -- sequence playhead
    local playhead = self.model.view.current_visible_step
    if playhead ~= nil then
        for i = 1, 7 do self.g:led(playhead, i, 1) end
    end
    -- transport
    if self.model.view.playing then
        self.g:led(1, 8, 0)
        self.g:led(2, 8, 15)
    else
        self.g:led(1, 8, 15)
        self.g:led(2, 8, 0)
    end
    self.g:refresh()
end

return Grid