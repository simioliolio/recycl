GridModel = require 'recycl/gridmodel'
GridViewModel = require 'recycl/gridviewmodel'

function init()
    clock_div = 4
    model = GridModel:new()
    model.transport_lambda = function(play)
        local t = clock.transport
        if play == true then t.start() else t.stop() end
    end
    model.update_lambda = function() redraw() end
    g = grid.connect()

    g.key = function(x, y, z)
        interpret_grid(x, y, z)
    end

    redraw()
end

function clock.transport.start()
    clock_id = clock.run(tick)
end

function clock.transport.stop()
    clock.cancel(clock_id)
end

function tick()
    while true do

        clock.sync(1 / clock_div)
    end
end

function interpret_grid(x, y, z)
    print("interpret grid " .. x .. y .. z)
    if x == 1 and y == 8 and z == 1 then model:stop() end
    if x == 2 and y == 8 and z == 1 then model:play() end
end

function redraw()
    g:all(0)
    if model.view.playing then
        g:led(1, 8, 0)
        g:led(2, 8, 15)
    else
        g:led(1, 8, 15)
        g:led(2, 8, 0)
    end
    g:refresh()
end
