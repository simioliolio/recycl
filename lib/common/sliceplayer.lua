SlicePlayer = {
    -- Called after request to update content
    on_render = function (ch, start, i, s) print("Error! on_render not set") end,

    -- Called when playhead poll is active
    on_playhead_poll = function (pos) print("Error! on_playhead_poll not set") end,

    -- Length of the loaded audio file
    length = 1,

    -- Whether SlicePlayer is playing
    playing = false
}

function SlicePlayer:setup_softcut()
    softcut.buffer_clear()
    audio.level_adc_cut(1)
    softcut.level_input_cut(1,2,1.0)
    softcut.level_input_cut(2,2,1.0)
    softcut.phase_quant(1,0.01)
    softcut.poll_start_phase()
    softcut.event_render(self.on_render) -- TODO: Move up?
end

function SlicePlayer:reset()
    for i=1,2 do
        softcut.enable(i,1)
        softcut.buffer(i,i)
        softcut.level(1,1.0)
        softcut.position(i,0)
        softcut.rate(i,1.0)
        softcut.fade_time(1,0)
    end
end

function SlicePlayer:register_playhead_poll()
    self.playhead_poll = poll.set('playhead', function(pos)
      self.on_playhead_poll(pos)
    end)
    self.playhead_poll.time = 0.1
end

function SlicePlayer:start_playhead_poll()
    self.playhead_poll:start()
end

function SlicePlayer:stop_playhead_poll()
    self.playhead_poll:stop()
end

-- Render some data from audio buffer. `on_render` will be called later with data.
function SlicePlayer:render(start_time,duration,no_of_values)
    softcut.render_buffer(1, util.clamp(start_time, 0.0, self.length), duration, no_of_values)
end

function SlicePlayer:load_file(file)
    softcut.buffer_clear_region(1,-1)
    if file ~= "cancel" then
        local ch, samples = audio.file_info(file)
        -- TODO: shouldn't hard code 48kHz
        self.length = samples / 48000
        -- TODO: Support stereo (instead of only split mono)
        softcut.buffer_read_mono(file,0,0,-1,1,1)
        softcut.buffer_read_mono(file,0,0,-1,1,2)
        engine.load_audio_file(file)
    end
end

function SlicePlayer:play(time)
    self.playing = true
    engine.play(time / self.length)
end

function SlicePlayer:play_slice(start_time, end_time)
    self.playing = true
    engine.play(start_time / self.length, end_time / self.length)
end

function SlicePlayer:stop()
    self.playing = false
    engine.stop()
end

return SlicePlayer