include 'recycl/lib/common/sequencer'
include 'recycl/lib/common/paramid'

SequencerParams = {
    connect = function()
        Sequencer.sequence_length = params:get(ParamID.seq_length)
        params:set_action(ParamID.seq_length, function(value)
            Sequencer.sequence_length = value
        end)
    end
}

return SequencerParams