Sequencer = include 'recycl/lib/common/sequencer'
SlicePlayer = include 'recycl/lib/common/sliceplayer'
SequenceEventType = include 'recycl/lib/common/sequenceeventtype'
Model = include 'recycl/lib/slice/model'

SequencePlayer = {

}

function SequencePlayer.connect_sequencer_to_slice_player()
    Sequencer:subscribe_to_event(function(step, event)
        -- Sequencer will send a nil event when there is no event
        if event == nil and SlicePlayer.playing == true then
            SlicePlayer:stop()
        elseif event ~= nil then
            if event.event_type == SequenceEventType.START then
                if #Model.slice_store.slice_times <= event.part then
                    print("error: sequencer requesting slice that doesn't exist")
                    return
                end
                local start_time = Model.slice_store.slice_times[event.part]
                local end_time = Model.slice_store.slice_times[event.part + 1]
                SlicePlayer:play_slice(start_time, end_time)
            end
        end
    end
)
end

return SequencePlayer