package.path = package.path .. ";../?.lua"

luaunit = require("luaunit")
require("waveformdisplay")

TestWaveformDisplay = {}

function TestWaveformDisplay:testSetWaveformData_whenStartTimeGreaterThanZero_thenSaveUnmodified()
    waveform = WaveformDisplay:new()
    dataStub = { 0.0, 0.1, 0.5, 1.0 }
    waveform:setWaveformData(0.2, dataStub)
    luaunit.assertEquals(waveform.waveform_samples, dataStub)
end

function TestWaveformDisplay:testSetWaveformData_whenStartTimeLessThanZero_thenAddZeros()
    waveform = WaveformDisplay:new()
    dataStub = { 0.0, 0.1, 0.5, 1.0 }
    expectedDataStub = { 0.0, 0.0, 0.0, 0.1, 0.5, 1.0}
    waveform.waveform_render_time_start = -1.0
    waveform:setWaveformData(0.5, dataStub)
    luaunit.assertEquals(waveform.waveform_samples, expectedDataStub)
end

function TestWaveformDisplay:testUpdate_thenCallsUpdateDataRequest() -- TODO: Remove?
    updateFunctionCalledWithStart = nil
    updateFunctionCalledWithDuration = nil
    updateFunction = function(start, duration) 
        updateFunctionCalledWithStart = start
        updateFunctionCalledWithDuration = duration
    end
    waveform = WaveformDisplay:new{updateDataRequest = updateFunction}
    waveform:update()
    luaunit.assertEquals(updateFunctionCalledWithStart, 0)
    luaunit.assertEquals(updateFunctionCalledWithDuration, 1)
end

function TestWaveformDisplay:testZoom_whenZoomOut_thenLargerDuration_thenEarlierStartTime()
    waveform = WaveformDisplay:new{
        waveform_render_duration = 10,
        waveform_render_time_start = 0,
        maximum_render_duration = 100,
        cursor_position_time = 5
    }
    waveform:zoom(1)
    luaunit.assertTrue(waveform.waveform_render_duration > 10)
    luaunit.assertTrue(waveform.waveform_render_time_start < 0)
end

function TestWaveformDisplay:testZoom_whenZoomIn_thenSmallerDuration_thenLaterStartTime()
    waveform = WaveformDisplay:new{
        waveform_render_duration = 10,
        waveform_render_time_start = 0,
        maximum_render_duration = 100,
        cursor_position_time = 5
    }
    waveform:zoom(-1)
    luaunit.assertTrue(waveform.waveform_render_duration < 10)
    luaunit.assertTrue(waveform.waveform_render_time_start > 0)
end

os.exit( luaunit.LuaUnit.run() )