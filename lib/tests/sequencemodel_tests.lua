-- To run:
-- $ cd <test file folder>
-- $ lua <test file>

require("test_helper")

luaunit = require("luaunit")
SequenceModel = require("lib/sequencepage/sequencemodel")
require 'lib/common/sequenceeventtype'

TestSequenceModel = {}

function TestSequenceModel:setUp()
    --
end

function TestSequenceModel:test_startAndTailModel_thenHasCorrectVisualModel()
    local raw_sequence = {}

    raw_sequence[1] = {{
        event_type = SequenceEventType.START,
        part = 1
    }}
    raw_sequence[2] = {{
        event_type = SequenceEventType.TAIL,
        part = 1
    }}

    local result = SequenceModel:raw_sequence_to_visual(raw_sequence)

    luaunit.assertEquals(result, {1, "~"})
end

os.exit( luaunit.LuaUnit.run() )