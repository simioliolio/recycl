GridViewModel = require 'recycl/gridviewmodel'

GridModel = {}

function GridModel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.view = GridViewModel:new()
    self.transport_lambda = function(play) end -- replace externally
    self.update_lambda = function() end
    -- self.sequencer = require 'recycl/sequencer'
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

-- /actions

return GridModel