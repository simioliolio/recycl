package.path = package.path .. ";../?.lua" .. ";../../?.lua" .. ";recycl/?.lua" .. ";recycl/tests/?.lua"

luaunit = require("luaunit")
GridModel = require("gridmodel")
GridViewModel = require("gridviewmodel")
require 'recycl/grideventtype'

TestGridModel = {}


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