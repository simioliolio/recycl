-- To run:
-- $ cd <test file folder>
-- $ lua <test file>

require("test_helper")

luaunit = require("luaunit")
require("waveformdisplay")

TestWaveformDisplay = {}

function TestWaveformDisplay:test_setWaveformData_whenStartTimeGreaterThanZero_thenSaveUnmodified()
    local waveform = WaveformDisplay:new()
    waveform.render_time_start = 0.1
    local dataStub = { 0.0, 0.1, 0.5, 1.0 }
    waveform:set_waveform_data(0.2, dataStub)
    luaunit.assertEquals(waveform.samples, dataStub)
end

function TestWaveformDisplay:test_setWaveformData_whenStartTimeLessThanZero_thenAddZeros()
    local waveform = WaveformDisplay:new()
    local dataStub = { 0.0, 0.1, 0.5, 1.0 }
    local expected_data_stub = { 0.0, 0.0, 0.0, 0.1, 0.5, 1.0}
    waveform.render_time_start = -1.0
    waveform:set_waveform_data(0.5, dataStub)
    luaunit.assertEquals(waveform.samples, expected_data_stub)
end

function TestWaveformDisplay:test_update_thenCallsUpdateDataRequest()
    local update_function_called_with_start = nil
    local update_function_called_with_duration = nil
    local update_function = function(start, duration)
        update_function_called_with_start = start
        update_function_called_with_duration = duration
    end
    waveform = WaveformDisplay:new{update_data_request = update_function}
    waveform:update()
    luaunit.assertEquals(update_function_called_with_start, -0.75)  -- Assert default values
    luaunit.assertEquals(update_function_called_with_duration, 1.5) --
end

function TestWaveformDisplay:test_zoom_whenZoomOut_thenLargerDuration_thenEarlierStartTime()
    local waveform = WaveformDisplay:new{
        render_duration = 10,
        render_time_start = 0,
        max_render_duration = 100
    }
    waveform:zoom(1)
    luaunit.assertTrue(waveform.render_duration > 10)
    luaunit.assertTrue(waveform.render_time_start < 0)
end

function TestWaveformDisplay:test_zoom_whenZoomIn_thenSmallerDuration_thenLaterStartTime()
    local waveform = WaveformDisplay:new{
        render_duration = 10,
        render_time_start = 0,
        max_render_duration = 100
    }
    waveform:zoom(-1)
    luaunit.assertTrue(waveform.render_duration < 10)
    luaunit.assertTrue(waveform.render_time_start > 0)
end

function TestWaveformDisplay_test_setCenter_thenChangeStart_thenUpdateContent()
    local update_function_called_with_start = nil
    local update_function_called_with_duration = nil
    local update_function = function(start, duration)
        update_function_called_with_start = start
        update_function_called_with_duration = duration
    end
    local waveform = WaveformDisplay:new{
        render_duration = 10,
        render_time_start = 0,
        max_render_duration = 100,
        update_data_request = update_function
    }
    waveform:set_center_and_update(10)
    luaunit.assertEquals(waveform.render_time_start, 5)
    luaunit.assertEquals(update_function_called_with_start, 5)
    luaunit.assertEquals(update_function_called_with_duration, 10)
end

os.exit( luaunit.LuaUnit.run() )