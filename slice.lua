-- norns.script.load("code/recycl/slice.lua")

engine.name = "Recycl"
engine.list_commands()

debug_mode = true
debug_file = "/home/we/dust/audio/common/The Breaks/11thhouse.wav"

fileselect = require 'fileselect'
table = require 'table'

saved = "..."
level = 1.0
length = 1
selecting_file = false
waveform_loaded = false

function load_file(file)
  softcut.buffer_clear_region(1,-1)
  selecting_file = false
  if file ~= "cancel" then
    local ch, samples = audio.file_info(file)
    length = samples / 48000 -- shouldn't hard code?
    softcut.buffer_read_mono(file,0,0,-1,1,1) -- only split mono for now?
    softcut.buffer_read_mono(file,0,0,-1,1,2) --
    engine.load_audio_file(file)
    reset()
    waveform_loaded = true
  end
end

function reset()
  for i=1,2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(1,1.0)
    softcut.position(i,0)
    softcut.rate(i,1.0)
    softcut.fade_time(1,0)
  end
  cursor_position_time = 0
  waveform_render_duration = 0.5
  waveform_render_time_start = cursor_position_time - (waveform_render_duration / 2)
  update_content(1, waveform_render_time_start, waveform_render_duration)
end

-- WAVEFORMS
local interval = 0
waveform_render_width = 128
waveform_samples = {}
waveform_render_duration = 1
waveform_render_time_start = 0
cursor_position_time = 0
scale = 30
minimum_render_duration = waveform_render_width / 48000 -- shouldn't hard code?

function on_render(ch, start, i, s)
  interval = i
  if waveform_render_time_start >= 0.0 then
    waveform_samples = s
  else
    -- waveform render sometimes shows data before the first sample, as cursor is 
    -- in the middle. softcut will not render a buffer if start time is negative.
    -- so, add an appropriate number of zeros to the start of waveform_samples
    local offset_samples = {}
    local time_when_before_zero = waveform_render_time_start
    local rendered_waveform_index = 1
    for i = 1, waveform_render_width do
      if time_when_before_zero < 0.0 then
        offset_samples[i] = 0.0
        time_when_before_zero = time_when_before_zero + interval
      else
        offset_samples[i] = s[rendered_waveform_index]
        rendered_waveform_index = rendered_waveform_index + 1
      end
    end
    waveform_samples = offset_samples
  end
  
  redraw()
end

function update_content(buffer,winstart,duration)
  softcut.render_buffer(buffer, util.clamp(winstart, 0.0, length), duration, waveform_render_width)
end
--/ WAVEFORMS

function init()
  softcut.buffer_clear()
  
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)

  softcut.phase_quant(1,0.01)
  softcut.poll_start_phase()
  softcut.event_render(on_render)

  reset()

  if debug_mode then load_file(debug_file) end
end

function key(n,z)
  if n==1 and z==1 then
    selecting_file = true
    fileselect.enter(_path.dust,load_file)
  elseif n==3 and z==1 then
    engine.play(cursor_position_time / length)
  elseif n==3 and z==0 then
    engine.stop()
  end
end

function enc(n,d)
  if n==1 then
  -- zoom
    local change_scalar = 0.9
    if d > 0 then
      change_scalar = 1.0 / change_scalar
    end
    waveform_render_duration = util.clamp(waveform_render_duration * change_scalar, minimum_render_duration, length)
    waveform_render_time_start = cursor_position_time - (waveform_render_duration / 2)
    update_content(1, waveform_render_time_start, waveform_render_duration)
  elseif n==2 then
  -- move cursor
    local jump = waveform_render_duration / waveform_render_width -- jump approx 1 pixel
    local cursor_offset = jump * d -- neg or pos offset depending on enc turn direction
    cursor_position_time = util.clamp(cursor_position_time + cursor_offset, 0.0, length)
    -- adjust start so cursor is always in the center of waveform render
    waveform_render_time_start = cursor_position_time - (waveform_render_duration / 2)
    update_content(1, waveform_render_time_start, waveform_render_duration)
  end
end

function redraw()
  screen.clear()
  if not waveform_loaded then
  -- show loading dialog
    screen.level(15)
    screen.move(62,50)
    screen.text_center("Hold K1 to load sample")
  else
  -- draw waveform
    screen.level(4)
    local x_pos = 0
    local zero_count = 0
    local non_zero_count = 0
    for i,s in ipairs(waveform_samples) do
      local height = util.round(math.abs(s) * (scale*level))
      if height <= 0 then zero_count = zero_count + 1 else non_zero_count = non_zero_count + 1 end
      screen.move(util.linlin(0,waveform_render_width,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
  -- draw cursor position
    screen.level(15)
    local waveform_render_time_end = waveform_render_time_start + waveform_render_duration
    screen.move(util.linlin(waveform_render_time_start,waveform_render_time_end,10,120,cursor_position_time),18)
    screen.line_rel(0, 35)
    screen.stroke()
  end
  
  screen.update()
end