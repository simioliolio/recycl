GridModel = require 'recycl/gridmodel'
GridViewModel = require 'recycl/gridviewmodel'
Sequencer = require 'recycl/sequencer'
GridEventType = require 'recycl/grideventtype'

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
    if y < 8 then model:sequencer_interaction(x, y, z) end
end

function redraw()
    g:all(0)
    for step_number, step in ipairs(model.view.sequence_data) do
        for part, event_type in ipairs(step) do
            -- TODO: Remove
            if step_number == 1 or step_number == 2 then
                print("step: " .. step_number .. " part: " .. part .. " event_type: " .. event_type)
            end

            if event_type == GridEventType.START then
                g:led(step_number, part, 15)
            elseif event_type == GridEventType.TAIL then
                g:led(step_number, part, 10)
            else
                -- leave blank
            end
        end
    end
    if model.view.playing then
        g:led(1, 8, 0)
        g:led(2, 8, 15)
    else
        g:led(1, 8, 15)
        g:led(2, 8, 0)
    end
    g:refresh()
end
