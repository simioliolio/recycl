GridModel = require 'recycl/gridmodel'
GridViewModel = require 'recycl/gridviewmodel'
Sequencer = require 'recycl/sequencer'

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
    for step_number, step in ipairs(model.view.sequence_steps) do
        for part, length in ipairs(step) do
            if step_number == 1 or step_number == 2 or step_number == 3 or step_number == 4 then
                -- print("step: " .. step_number .. " part: " .. part .. " length: " .. length)
            end

            if length == 0 then goto continue end
            -- bright led for start of note
            g:led(step_number, part, 15)
            -- then make a tail to the right
            local tail_length = length - 1
            local next_step = step_number + 1
            for i = next_step, step_number + tail_length do
                -- less bright led for tail of note if present
                g:led(i, part, 10)
            end
            ::continue::
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
