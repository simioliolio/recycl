Sequencer = include "recycl/lib/common/sequencer"
SequencerModel = include "recycl/lib/sequencepage/sequencemodel"

-- 1-N  :   Trigger slice
-- ~    :   Continue
-- .    :   Rest
-- ]    :   End

SequencePage = {
    raw_sequence = {}
}

function SequencePage:init()
    self.raw_sequence = Sequencer.sequence
    Sequencer:subscribe_to_change(function(sequence) self:sequence_changed(sequence) end)
end

function SequencePage:sequence_changed(sequence)
    self.raw_sequence = sequence
    local visual_sequence = SequenceModel:raw_sequence_to_visual(self.raw_sequence)
    -- TODO: Draw visual_sequence
end

function SequencePage:key(n,z)
    -- TODO: What are keys for?
end

function SequencePage:enc(n,d)
    -- TODO: Use encoder to move cursor through sequence
    -- TODO: Use encoder to change event at cursor
end

function SlicePage:redraw()
    if self.redraw_lock == true then return end
    screen.clear()
end

return SequencePage