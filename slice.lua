-- norns.script.load("code/recycl/slice.lua")

engine.name = "Recycl"
engine.list_commands()
poll.list_names()

debug_mode = true
debug_file = "/home/we/dust/audio/common/The Breaks/11thhouse.wav"

fileselect = require 'fileselect'
table = require 'table'

saved = "..."
level = 1.0
length = 1
selecting_file = false
waveform_loaded = false

include("waveformdisplay")
waveform_display = WaveformDisplay:new()

include("model")
model = Model:new()

-- startup

function init()
  setup_softcut()
  register_playhead_poll()
  reset()
  if debug_mode then load_file(debug_file) end
end

function setup_softcut()
  softcut.buffer_clear()
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)
  softcut.phase_quant(1,0.01)
  softcut.poll_start_phase()
  softcut.event_render(on_render)
end

function register_playhead_poll()
  playhead_poll = poll.set('playhead', function(pos)
    playhead_position = pos
    redraw()
  end)
  playhead_poll.time = 0.1
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
  waveform_display = WaveformDisplay:new(
    {update_data_request = update_content,
    max_render_duration = length}
  )
  model = Model:new()
  model.slice_store:set_length(length)
  playhead_position = nil
  -- trigger intial waveform load
  update_content(waveform_display.render_time_start, waveform_display.render_duration)
end

--/ startup

-- file loading

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

--/ file loading

-- waveform view
cursor_position_time = 0
scale = 30 -- TODO: Rename

-- softcut render event callback
function on_render(ch, start, i, s)
  waveform_display:set_waveform_data(i, s)
  redraw()
end

-- trigger render event
function update_content(winstart,duration)
  softcut.render_buffer(1, util.clamp(winstart, 0.0, length), duration, waveform_display.render_width)
end

--/ waveform view

-- user input

function key(n,z)
  if n==1 and z==1 then
    selecting_file = true
    fileselect.enter(_path.dust,load_file)
  elseif n==2 and z==1 then
    model.slice_store:add_slice(cursor_position_time)
    redraw()
  elseif n==3 and z==1 then
    engine.play(cursor_position_time / length)
    playhead_poll:start()
  elseif n==3 and z==0 then
    engine.stop()
    playhead_poll:stop()
    playhead_position = nil
    redraw()
  end
end

function enc(n,d)
  if n==1 then
    waveform_display:zoom(d)
  elseif n==2 then
  -- move cursor
    local jump = waveform_display.render_duration / waveform_display.render_width -- jump approx 1 pixel
    local cursor_offset = jump * d -- neg or pos offset depending on enc turn direction
    cursor_position_time = util.clamp(cursor_position_time + cursor_offset, 0.0, length)
    -- adjust start so cursor is always in the center of waveform render
    -- TODO: Could move this to waveform?
    waveform_display.render_time_start = cursor_position_time - (waveform_display.render_duration / 2)
    waveform_display.cursor_position_time = cursor_position_time
    update_content(waveform_display.render_time_start, waveform_display.render_duration)
  end
end

--/ user input

-- screen drawing

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
    for i,s in ipairs(waveform_display.samples) do
      local height = util.round(math.abs(s) * (scale*level))
      screen.move(util.linlin(0,waveform_display.render_width,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
  -- draw cursor position
    local start_time = waveform_display.render_time_start
    local end_time = start_time + waveform_display.render_duration
    screen.level(15)
    screen.move(util.linlin(start_time,end_time,10,120,cursor_position_time),18)
    screen.line_rel(0, 35)
    screen.stroke()
  -- draw playhead
    if (playhead_position ~= nil) and (playhead_position < end_time) then
      screen.level(2)
      screen.move(util.linlin(start_time, end_time, 10, 120, playhead_position), 0)
      screen.line_rel(0, 64)
      screen.stroke()
    end
  -- draw slice times
    local slice_times_to_display = model.slice_store:slices_in_range(start_time, end_time)
    for i, sliceTime in ipairs(slice_times_to_display) do
      screen.level(5)
      local slice_x_pos = util.linlin(start_time, end_time, 10, 120, sliceTime)
      screen.move(slice_x_pos, 4)
      screen.line_rel(0, 60)
      screen.stroke()
      screen.circle(slice_x_pos, 4, 2)
      screen.stroke()
    end
  end
  
  screen.update()
end

--/ screen drawing