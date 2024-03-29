-- To run:
-- $ cd <test file folder>
-- $ lua <test file>

require("test_helper")

luaunit = require("luaunit")
require('lib/common/sequencer')

TestSequencer = {}

function TestSequencer:setUp()
    Sequencer:reset()
end

function TestSequencer:test_init_thenStepIsNil()
    local seq = Sequencer
    luaunit.assertEquals(seq.current_step, nil)
end

function TestSequencer:test_advance_thenCurrentStepIsOne()
    local seq = Sequencer
    seq:advance()
    luaunit.assertEquals(seq.current_step, 1)
end

function TestSequencer:test_add_whenNothingAdded_thenNoEvent()
    local seq = Sequencer
    luaunit.assertEquals(seq.sequence[1], nil)
end

function TestSequencer:test_addEventAtStepOne_thenAddsToSequence()
    local seq = Sequencer
    seq:add(1, {"data", 1})
    luaunit.assertEquals(seq.sequence[1], {{"data", 1}})
end

function TestSequencer:test_addEventAtStepTwo_thenAddsToSequence()
    local seq = Sequencer
    seq:add(2, {"data", 1})
    luaunit.assertEquals(seq.sequence[2], {{"data", 1}})
end

function TestSequencer:test_addTwoEventsAtStepOne_thenAddsToSequence()
    local seq = Sequencer
    seq:add(1, {"data", 1})
    seq:add(1, {"data_2", 2})
    luaunit.assertEquals(seq.sequence[1], {{"data", 1}, {"data_2", 2}})
end

function TestSequencer:test_eventCallback_whenAdvance_thenCallsEventCallbackWithEvent()
    local seq = Sequencer
    local event_data_stub = {"data", 1}
    seq:add(1, event_data_stub)
    local event_table_from_callback = nil
    seq:subscribe_to_event(function(_, event_table)
        event_table_from_callback = event_table
        end
    )
    seq:advance()
    luaunit.assertEquals(event_table_from_callback, event_data_stub)
end

function TestSequencer:test_eventCallback_whenAdvance_thenCallsEventCallbackWithEachEvent()
    local seq = Sequencer
    local event_data_stub = {"data", 1}
    local event_data_stub_2 = {"data_2", 2}
    seq:add(1, event_data_stub)
    seq:add(1, event_data_stub_2)
    local events_from_callback = {}
    seq:subscribe_to_event(function(_, event_table)
        table.insert(events_from_callback, event_table)
        end
    )
    seq:advance()
    luaunit.assertEquals(events_from_callback, {event_data_stub, event_data_stub_2})
end

function TestSequencer:test_clear_thenClears()
    local seq = Sequencer
    seq.sequence[1] = {"data", 2}
    seq:clear(1)
    luaunit.assertEquals(seq.sequence[1], nil)
end

function TestSequencer:test_clear_whenAdded_thenClears()
    local seq = Sequencer
    seq:add(1, {"data", 2})
    seq:clear(1)
    luaunit.assertEquals(seq.sequence[1], nil)
end

os.exit( luaunit.LuaUnit.run() )