GridModel = include 'recycl/lib/grid/gridmodel'
GridViewModel = include 'recycl/lib/grid/gridviewmodel'
Sequencer = include 'recycl/lib/common/sequencer'
SequenceEventType = include 'recycl/lib/common/sequenceeventtype'
SlicePlayer = include 'recycl/lib/common/sliceplayer'
ParamID = include 'recycl/lib/common/paramid'
OnScreenGrid = include 'recycl/lib/grid/onscreengrid'

Grid = {}

function Grid:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.clock_div = params:get(ParamID.clock_div)
    params:set_action(ParamID.clock_div, function(val)
        print("getting clock div " .. val)
        self.clock_div = val
    end)

    clock.transport.start = function() self:start_clock() end
    clock.transport.stop = function() self:stop_clock() end

    self.model = GridModel:new()
    self.model.transport_lambda = function(play)
        local t = clock.transport
        if play == true then
            t.start()
        else
            t.stop()
            SlicePlayer:stop() -- Stop slice if playing
        end
    end
    self.model:set_redraw(function() self:redraw() end)
    self.model.set_clock_div = function(model_clock_div)
        self.clock_div = model_clock_div
    end

    OnScreenGrid:init()
    OnScreenGrid:subscribe_to_keys(function(x, y, z) self:interaction(x, y, z) end)

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
    OnScreenGrid:all(0)
    -- sequence
    for step_number, step in ipairs(self.model.view.sequence_data) do
        for part, event_type in ipairs(step) do
            if event_type == SequenceEventType.START then
                OnScreenGrid:led(step_number, part, 15)
            elseif event_type == SequenceEventType.TAIL then
                OnScreenGrid:led(step_number, part, 10)
            end
        end
    end
    -- sequence playhead
    local playhead = self.model.view.current_visible_step
    if playhead ~= nil then
        for i = 1, 7 do OnScreenGrid:led(playhead, i, 1) end
    end
    -- transport
    if self.model.view.playing then
        OnScreenGrid:led(1, 8, 0)
        OnScreenGrid:led(2, 8, 15)
    else
        OnScreenGrid:led(1, 8, 15)
        OnScreenGrid:led(2, 8, 0)
    end
    OnScreenGrid:refresh()
end

return Grid