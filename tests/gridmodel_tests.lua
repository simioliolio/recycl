package.path = package.path .. ";../?.lua" .. ";../../?.lua"

luaunit = require("luaunit")
GridModel = require("gridmodel")
GridViewModel = require("gridviewmodel")

TestGridModel = {}

function TestGridModel:test_seqInter_whenOn_whenOffForSamePart_thenRightSeq()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{1, 1}})
end

function TestGridModel:test_seqInter_whenOn_whenOnOffForOtherPart_whenOff_thenRightSeq()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{1, 1}})
end

function TestGridModel:test_seqInter_whenExistingEvent_whenOnOff_thenClearsSeq()
    local sut = GridModel:new()
    sut.sequencer.sequence[1] = {{1, 1}}
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], nil)
end

function TestGridModel:test_seqInter_whenMultipleOnForPart_thenSeqEventWithCorrectLength()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(3, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(3, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{1, 3}})
end

function TestGridModel:test_seqInter_whenExistingEvent_whenAddLongEventBefore_thenOverlappingEventCleared()
    local sut = GridModel:new()
    sut.sequencer.sequence[2] = {{1, 1}}
    sut.sequencer.sequence[4] = {{1, 1}}
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(3, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(3, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[2], nil)        -- removed
    luaunit.assertEquals(sut.sequencer.sequence[4], {{1, 1}})   -- remains
end

function TestGridModel:test_updateViewSeq_thenReflectsSequence()
    local sut = GridModel:new()
    sut.sequencer.sequence[1] = {{1, 1}}
    sut:update_view_seq()
    luaunit.assertEquals(sut.view.sequence_data[1][1], 1)
end

function TestGridModel:test_updateViewSeq_whenDifferentVisiblePart_thenReflectsSequence()
    local sut = GridModel:new()
    sut.view.first_visible_part = 3
    sut.sequencer.sequence[1] = {{4, 1}}
    sut:update_view_seq()
    luaunit.assertEquals(sut.view.sequence_data[1][2], 1)
end

function TestGridModel:test_updateViewSeq_whenDifferentVisibleStep_thenReflectsSequence()
    local sut = GridModel:new()
    sut.view.first_visible_step = 4
    sut.sequencer.sequence[5] = {{1, 1}}
    sut:update_view_seq()
    luaunit.assertEquals(sut.view.sequence_data[2][1], 1)
end



os.exit( luaunit.LuaUnit.run() )