require("util")

WaveformDisplay = {
    render_width = 128,
    samples = {},
    render_duration = 1.5,
    render_time_start = 0 - (1.5 / 2),
    min_render_duration = 128 / 48000,  -- TODO: don't hard code sample rate
    max_render_duration = 1,            -- Should set when file length is known
    update_data_request = function(start, duration, no_of_values) print("Error! update_data_request callback not set") end
}

function WaveformDisplay:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function WaveformDisplay:update()
    self.update_data_request(self.render_time_start, self.render_duration)
end

-- Set waveform data recently requested
function WaveformDisplay:set_waveform_data(interval, data)
    if self.render_time_start >= 0.0 then
        self.samples = data
    else
        -- waveform render sometimes shows data before the first sample, as cursor is
        -- shown in the middle of the display. softcut will not render a buffer if
        -- start time is negative. so, add an appropriate number of zeros to the start
        -- of samples table
        local offset_samples = {}
        local time_when_before_zero = self.render_time_start
        local rendered_waveform_index = 1
        for i = 1, self.render_width do
            if time_when_before_zero < 0.0 then
                offset_samples[i] = 0.0
                time_when_before_zero = time_when_before_zero + interval
            else
                offset_samples[i] = data[rendered_waveform_index]
                rendered_waveform_index = rendered_waveform_index + 1
            end
        end
        self.samples = offset_samples
    end
end

-- d: positive to zoom out. negative to zoom in.
function WaveformDisplay:zoom(d)
    -- find center
    local center = self.render_time_start + (self.render_duration / 2)
    -- scale render duration
    local change_scalar = 0.9
    if d > 0 then
      change_scalar = 1.0 / change_scalar
    end
    self.render_duration = util.clamp(self.render_duration * change_scalar, self.min_render_duration, self.max_render_duration)
    -- change start time based on center and new duration
    self.render_time_start = center - (self.render_duration / 2)
    -- update
    self.update_data_request(self.render_time_start, self.render_duration, self.render_width)
end

function WaveformDisplay:set_center_and_update(time)
    self.render_time_start = time - (self.render_duration / 2)
    self.update_data_request(self.render_time_start, self.render_duration, self.render_width)
end

return WaveformDisplay