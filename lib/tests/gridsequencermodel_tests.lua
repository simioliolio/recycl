-- To run:
-- $ cd <test file folder>
-- $ lua <test file>

require("test_helper")

luaunit = require("luaunit")
GridSequencerModel = require("lib/grid/gridsequencermodel")
GridViewModel = require("lib/grid/gridviewmodel")
ParamID = require 'lib/common/paramid'
require 'common/sequenceeventtype'
require 'common/sequencer'

TestGridSequencerModel = {}

function TestGridSequencerModel:setUp()
    Sequencer:reset()
    params.get = function(self, id) return 8 end
end

function TestGridSequencerModel:test_seqInter_whenAddOverTail_thenReplaceTail_thenRemoveOrphanTail()
    local sut = GridSequencerModel:new()

    local start_stub = {}
    start_stub.event_type = SequenceEventType.START
    start_stub.part = 1
    local tail_stub = {}
    tail_stub.event_type = SequenceEventType.TAIL
    tail_stub.part = 1
    Sequencer.sequence[1] = {start_stub}
    Sequencer.sequence[2] = {tail_stub}
    Sequencer.sequence[3] = {tail_stub}

    sut:sequencer_interaction(2, 1, 1)
    sut:sequencer_interaction(2, 1, 0)

    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[3], nil)
end

function TestGridSequencerModel:test_seqInter_whenNoExisting_thenAdd()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
end

function TestGridSequencerModel:test_seqInter_whenExisting_whenPressingExistingStart_thenRemove()
    local sut = GridSequencerModel:new()
    local start_stub = {}
    start_stub.event_type = SequenceEventType.START
    start_stub.part = 1
    Sequencer.sequence[1] = {start_stub}
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], nil)
end

function TestGridSequencerModel:test_seqInter_whenExisting_whenPressingAnotherPartAtSameStep_thenReplace()
    local sut = GridSequencerModel:new()
    local start_stub = {}
    start_stub.event_type = SequenceEventType.START
    start_stub.part = 1
    Sequencer.sequence[1] = {start_stub}
    sut:sequencer_interaction(1, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=2}})
end

function TestGridSequencerModel:test_seqInter_whenPressAndHoldTwoNextDoor_thenExtends()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(2, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(2, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="tail", part=1}})
end

function TestGridSequencerModel:test_seqInter_whenLongNote_whenNoteOnOtherPart_thenReplaces()
    local sut = GridSequencerModel:new()
    local start_stub = {}
    start_stub.event_type = SequenceEventType.START
    start_stub.part = 1
    local tail_stub = {}
    tail_stub.event_type = SequenceEventType.TAIL
    tail_stub.part = 1
    Sequencer.sequence[1] = {start_stub}
    Sequencer.sequence[2] = {tail_stub}
    Sequencer.sequence[3] = {tail_stub}
    sut:sequencer_interaction(1, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=2}})
    luaunit.assertEquals(Sequencer.sequence[2], nil)
end

function TestGridSequencerModel:test_seqInter_whenLongNote_whenNoteOnOtherPartDuringTail_thenReplacesTail()
    local sut = GridSequencerModel:new()
    local start_stub = {}
    start_stub.event_type = SequenceEventType.START
    start_stub.part = 1
    local tail_stub = {}
    tail_stub.event_type = SequenceEventType.TAIL
    tail_stub.part = 1
    Sequencer.sequence[1] = {start_stub}
    Sequencer.sequence[2] = {tail_stub}
    Sequencer.sequence[3] = {tail_stub}
    sut:sequencer_interaction(2, 2, 1)
    sut:sequencer_interaction(2, 2, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="start", part=2}})
end

function TestGridSequencerModel:test_seqInter_whenPressAndHoldTwoFarAway_thenExtends()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="tail", part=1}})
    luaunit.assertEquals(Sequencer.sequence[3], {{event_type="tail", part=1}})
    luaunit.assertEquals(Sequencer.sequence[4], {{event_type="tail", part=1}})
    luaunit.assertEquals(Sequencer.sequence[5], nil)
end

function TestGridSequencerModel:test_seqInter_whenExistingEvents_whenAddNewAtStart_thenRemovesExisting()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], nil)
    luaunit.assertEquals(Sequencer.sequence[2], nil)
    luaunit.assertEquals(Sequencer.sequence[3], nil)
    luaunit.assertEquals(Sequencer.sequence[4], nil)
    luaunit.assertEquals(Sequencer.sequence[5], nil)
end

function TestGridSequencerModel:test_seqInter_whenExistingEvents_whenAddNewOnTail_thenRemovesExisting()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(2, 1, 1) -- Add event
    sut:sequencer_interaction(2, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[3], nil)
    luaunit.assertEquals(Sequencer.sequence[4], nil)
    luaunit.assertEquals(Sequencer.sequence[5], nil)
end

function TestGridSequencerModel:test_seqInter_whenExistingEvents_whenAddNewAtStartFor2ndPart_thenRemovesExisting()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(1, 2, 1) -- Add event
    sut:sequencer_interaction(1, 2, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=2}})
    luaunit.assertEquals(Sequencer.sequence[2], nil)
    luaunit.assertEquals(Sequencer.sequence[3], nil)
    luaunit.assertEquals(Sequencer.sequence[4], nil)
    luaunit.assertEquals(Sequencer.sequence[5], nil)
end

function TestGridSequencerModel:test_seqInter_whenExistingEvents_whenAddNewOnTailFor2ndPart_thenRemovesExisting()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(2, 2, 1) -- Add event
    sut:sequencer_interaction(2, 2, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="start", part=2}})
    luaunit.assertEquals(Sequencer.sequence[3], nil)
    luaunit.assertEquals(Sequencer.sequence[4], nil)
    luaunit.assertEquals(Sequencer.sequence[5], nil)
end

function TestGridSequencerModel:test_seqInter_whenExistingTailEvents_whenAddNewWithLength_thenRemovesExistingTail()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(2, 1, 1) -- Add event
    sut:sequencer_interaction(2, 1, 0)
    sut:sequencer_interaction(2, 1, 1) -- Extend event
    sut:sequencer_interaction(3, 1, 1)
    sut:sequencer_interaction(2, 1, 0)
    sut:sequencer_interaction(3, 1, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="start", part=1}})
    luaunit.assertEquals(Sequencer.sequence[3], {{event_type="tail", part=1}})
    luaunit.assertEquals(Sequencer.sequence[4], nil)
    luaunit.assertEquals(Sequencer.sequence[5], nil)
end

function TestGridSequencerModel:test_seqInter_whenExistingStartEvents_whenAddNewWithLengthOnDifferentPart_thenRemovesExisting()
    local sut = GridSequencerModel:new()
    sut:sequencer_interaction(2, 1, 1) -- Add event
    sut:sequencer_interaction(2, 1, 0)
    sut:sequencer_interaction(1, 2, 1) -- Add event before on different part
    sut:sequencer_interaction(1, 2, 0)
    sut:sequencer_interaction(1, 2, 1) -- Extend new event
    sut:sequencer_interaction(3, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    sut:sequencer_interaction(3, 2, 0)
    luaunit.assertEquals(Sequencer.sequence[1], {{event_type="start", part=2}})
    luaunit.assertEquals(Sequencer.sequence[2], {{event_type="tail", part=2}})
    luaunit.assertEquals(Sequencer.sequence[3], {{event_type="tail", part=2}})
    luaunit.assertEquals(Sequencer.sequence[4], nil)
end

function TestGridSequencerModel:test_seqInter_whenStepBeyondSeqLen_thenGrowsSeqLen()
    local sut = GridSequencerModel:new()
    -- emulate params behaviour
    params.get = function(self, id) return 1 end
    local set_step = nil
    params.set = function(self, id, data, action)
        if id == ParamID.seq_length then
            set_step = data
        end
    end
    sut:sequencer_interaction(2, 1, 1) -- Add event
    sut:sequencer_interaction(2, 1, 0)
    luaunit.assertEquals(set_step, 2)
end

os.exit( luaunit.LuaUnit.run() )