package.path = package.path .. ";../?.lua" .. ";../../?.lua"

luaunit = require("luaunit")
GridModel = require("gridmodel")
GridViewModel = require("gridviewmodel")
require 'recycl/grideventtype'

TestGridModel = {}

function TestGridModel:test_seqInter_whenAddOverTail_thenReplaceTail_thenRemoveOrphanTail()
    local sut = GridModel:new()

    local start_stub = {}
    start_stub.event_type = GridEventType.START
    start_stub.part = 1
    local tail_stub = {}
    tail_stub.event_type = GridEventType.TAIL
    tail_stub.part = 1
    sut.sequencer.sequence[1] = {start_stub}
    sut.sequencer.sequence[2] = {tail_stub}
    sut.sequencer.sequence[3] = {tail_stub}

    sut:sequencer_interaction(2, 1, 1)
    sut:sequencer_interaction(2, 1, 0)

    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[3], nil)
end

function TestGridModel:test_seqInter_whenNoExisting_thenAdd()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
end

function TestGridModel:test_seqInter_whenExisting_whenPressingExistingStart_thenRemove()
    local sut = GridModel:new()
    local start_stub = {}
    start_stub.event_type = GridEventType.START
    start_stub.part = 1
    sut.sequencer.sequence[1] = {start_stub}
    sut:sequencer_interaction(1, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], nil)
end

function TestGridModel:test_seqInter_whenExisting_whenPressingAnotherPartAtSameStep_thenReplace()
    local sut = GridModel:new()
    local start_stub = {}
    start_stub.event_type = GridEventType.START
    start_stub.part = 1
    sut.sequencer.sequence[1] = {start_stub}
    sut:sequencer_interaction(1, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=2}})
end

function TestGridModel:test_seqInter_whenPressAndHoldTwoNextDoor_thenExtends()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(2, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(2, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="tail", part=1}})
end

function TestGridModel:test_seqInter_whenLongNote_whenNoteOnOtherPart_thenReplaces()
    local sut = GridModel:new()
    local start_stub = {}
    start_stub.event_type = GridEventType.START
    start_stub.part = 1
    local tail_stub = {}
    tail_stub.event_type = GridEventType.TAIL
    tail_stub.part = 1
    sut.sequencer.sequence[1] = {start_stub}
    sut.sequencer.sequence[2] = {tail_stub}
    sut.sequencer.sequence[3] = {tail_stub}
    sut:sequencer_interaction(1, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=2}})
    luaunit.assertEquals(sut.sequencer.sequence[2], nil)
end

function TestGridModel:test_seqInter_whenLongNote_whenNoteOnOtherPartDuringTail_thenReplacesTail()
    local sut = GridModel:new()
    local start_stub = {}
    start_stub.event_type = GridEventType.START
    start_stub.part = 1
    local tail_stub = {}
    tail_stub.event_type = GridEventType.TAIL
    tail_stub.part = 1
    sut.sequencer.sequence[1] = {start_stub}
    sut.sequencer.sequence[2] = {tail_stub}
    sut.sequencer.sequence[3] = {tail_stub}
    sut:sequencer_interaction(2, 2, 1)
    sut:sequencer_interaction(2, 2, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="start", part=2}})
end

function TestGridModel:test_seqInter_whenPressAndHoldTwoFarAway_thenExtends()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="tail", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[3], {{event_type="tail", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[4], {{event_type="tail", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[5], nil)
end

function TestGridModel:test_seqInter_whenExistingEvents_whenAddNewAtStart_thenRemovesExisting()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], nil)
    luaunit.assertEquals(sut.sequencer.sequence[2], nil)
    luaunit.assertEquals(sut.sequencer.sequence[3], nil)
    luaunit.assertEquals(sut.sequencer.sequence[4], nil)
    luaunit.assertEquals(sut.sequencer.sequence[5], nil)
end

function TestGridModel:test_seqInter_whenExistingEvents_whenAddNewOnTail_thenRemovesExisting()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(2, 1, 1) -- Add event
    sut:sequencer_interaction(2, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[3], nil)
    luaunit.assertEquals(sut.sequencer.sequence[4], nil)
    luaunit.assertEquals(sut.sequencer.sequence[5], nil)
end

function TestGridModel:test_seqInter_whenExistingEvents_whenAddNewAtStartFor2ndPart_thenRemovesExisting()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(1, 2, 1) -- Add event
    sut:sequencer_interaction(1, 2, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=2}})
    luaunit.assertEquals(sut.sequencer.sequence[2], nil)
    luaunit.assertEquals(sut.sequencer.sequence[3], nil)
    luaunit.assertEquals(sut.sequencer.sequence[4], nil)
    luaunit.assertEquals(sut.sequencer.sequence[5], nil)
end

function TestGridModel:test_seqInter_whenExistingEvents_whenAddNewOnTailFor2ndPart_thenRemovesExisting()
    local sut = GridModel:new()
    sut:sequencer_interaction(1, 1, 1) -- Add event
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(1, 1, 1) -- Extend event
    sut:sequencer_interaction(4, 1, 1)
    sut:sequencer_interaction(1, 1, 0)
    sut:sequencer_interaction(4, 1, 0)
    sut:sequencer_interaction(2, 2, 1) -- Add event
    sut:sequencer_interaction(2, 2, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="start", part=2}})
    luaunit.assertEquals(sut.sequencer.sequence[3], nil)
    luaunit.assertEquals(sut.sequencer.sequence[4], nil)
    luaunit.assertEquals(sut.sequencer.sequence[5], nil)
end

function TestGridModel:test_seqInter_whenExistingTailEvents_whenAddNewWithLength_thenRemovesExistingTail()
    local sut = GridModel:new()
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
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[3], {{event_type="tail", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[4], nil)
    luaunit.assertEquals(sut.sequencer.sequence[5], nil)
end

function TestGridModel:test_seqInter_whenExistingStartEvents_whenAddNewWithLengthOnDifferentPart_thenRemovesExisting()
    local sut = GridModel:new()
    sut:sequencer_interaction(2, 1, 1) -- Add event
    sut:sequencer_interaction(2, 1, 0)
    sut:sequencer_interaction(1, 2, 1) -- Add event before on different part
    sut:sequencer_interaction(1, 2, 0)
    sut:sequencer_interaction(1, 2, 1) -- Extend new event
    sut:sequencer_interaction(3, 2, 1)
    sut:sequencer_interaction(1, 2, 0)
    sut:sequencer_interaction(3, 2, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=2}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="tail", part=2}})
    luaunit.assertEquals(sut.sequencer.sequence[3], {{event_type="tail", part=2}})
    luaunit.assertEquals(sut.sequencer.sequence[4], nil)
end

function TestGridModel:test_interaction_thenIsSeqInteraction()
    local sut = GridModel:new()
    sut:interaction(1, 1, 1)
    sut:interaction(1, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
end

function TestGridModel:test_interaction_whenOnPressCol1Row8_thenStop()
    local sut = GridModel:new()
    local transport_lambda_input = true
    sut.transport_lambda = function(input) transport_lambda_input = input end
    sut:interaction(1, 8, 1)
    sut:interaction(1, 8, 0)
    luaunit.assertEquals(sut.view.playing, false)
    luaunit.assertEquals(transport_lambda_input, false)
end

function TestGridModel:test_interaction_whenOnPressCol2Row8_thenPlay()
    local sut = GridModel:new()
    local transport_lambda_input = false
    sut.transport_lambda = function(input) transport_lambda_input = input end
    sut:interaction(2, 8, 1)
    sut:interaction(2, 8, 0)
    luaunit.assertEquals(sut.view.playing, true)
    luaunit.assertEquals(transport_lambda_input, true)
end

function TestGridModel:test_interaction_when8thRow_whenOnPressCol3_thenSwitchModeToClockDiv()
    local sut = GridModel:new()
    sut:interaction(3, 8, 1)
    luaunit.assertEquals(sut.mode, sut.Modes.CLOCK_DIV)
end

function TestGridModel:test_interaction_when8thRow_whenOnPressCol3_whenOffPressCol3_thenSwitchModeBackToSeq()
    local sut = GridModel:new()
    sut:interaction(3, 8, 1)
    sut:interaction(3, 8, 0)
    luaunit.assertEquals(sut.mode, sut.Modes.SEQUENCE)
end

-- TODO: More definitive test for when switching mode
function TestGridModel:test_interaction_whenSeqInterOn_whenSwitchMode_whenSeqInterOff_thenOffStillEditsSequence()
    local sut = GridModel:new()
    sut:interaction(1, 1, 1) -- Add event
    sut:interaction(1, 1, 0)
    sut:interaction(1, 1, 1) -- Extend event
    sut:interaction(4, 1, 1)
    sut:interaction(3, 8, 1) -- Change mode
    sut:interaction(1, 1, 0) -- finish extending
    sut:interaction(4, 1, 0)
    luaunit.assertEquals(sut.sequencer.sequence[1], {{event_type="start", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[2], {{event_type="tail", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[3], {{event_type="tail", part=1}})
    luaunit.assertEquals(sut.sequencer.sequence[4], {{event_type="tail", part=1}})
end


os.exit( luaunit.LuaUnit.run() )