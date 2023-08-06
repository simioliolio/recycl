SequenceEventType = require('common.sequenceeventtype')

SequenceModel = {
    visual_sequence = {} -- array of characters?
}

function SequenceModel:raw_sequence_to_visual(raw_sequence)
    local visual_sequence = {}
    for i, event_data in ipairs(raw_sequence) do
        if #event_data < 1 then goto continue end

        if #event_data > 1 then print("cannot display mulitple events in simple screen sequence.") end
        local event = event_data[1]

        if event.event_type == SequenceEventType.TAIL then
            visual_sequence[i] = "~"
        elseif event.event_type == SequenceEventType.START then
            visual_sequence[i] = event.part
        end
        ::continue::
    end
    return visual_sequence
end
return SequenceModel