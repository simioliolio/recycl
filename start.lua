-- norns.script.load("code/recycl/start.lua")
debug_mode = true
debug_file = "/home/we/dust/audio/common/The Breaks/11thhouse.wav"

fileselect = require 'fileselect'
table = require 'table'

saved = "..."
level = 1.0
length = 1
position = 1
selecting_file = false
waveform_loaded = false
samples_represented_in_render = length -- Should delete this variable if centering cursor

function load_file(file)
  softcut.buffer_clear_region(1,-1)
  selecting_file = false
  if file ~= "cancel" then
    local ch, samples = audio.file_info(file)
    length = samples/48000
    samples_represented_in_render = length -- initially display the whole file
    softcut.buffer_read_mono(file,0,1,-1,1,1)
    softcut.buffer_read_mono(file,0,1,-1,1,2)
    reset()
    waveform_loaded = true
  end
end

function update_positions(i,pos)
  -- position = (pos - 1) / length -- note: position now controller by enc
  if selecting_file == false then redraw() end
end

function reset()
  for i=1,2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(1,1.0)
    softcut.loop(i,1)
    softcut.loop_start(i,1)
    softcut.loop_end(i,1+length)
    softcut.position(i,1)
    softcut.rate(i,1.0)
    -- softcut.play(1,1) -- do not play in this mode
    softcut.fade_time(1,0)
  end

  update_content(1,1,samples_represented_in_render,128)
end

-- WAVEFORMS
local interval = 0
waveform_samples = {}
scale = 30

function on_render(ch, start, i, s)
  waveform_samples = s
  interval = i
  redraw()
end

function update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end
--/ WAVEFORMS

function init()
  softcut.buffer_clear()
  
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)

  softcut.phase_quant(1,0.01)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()
  softcut.event_render(on_render)

  reset()

  if debug_mode then load_file(debug_file) end
end

function key(n,z)
  if n==1 and z==1 then
    selecting_file = true
    fileselect.enter(_path.dust,load_file)
  end
end

function enc(n,d)
  if n==1 then
    -- level = util.clamp(level+d/100,0,2)
    -- softcut.level(1,level)
    local change_scalar = 0.9
    if d > 0 then
      change_scalar = 1.0 / change_scalar
    end
    samples_represented_in_render = samples_represented_in_render * change_scalar
    update_content(1, 1, samples_represented_in_render, 128)
  end
  redraw()
end

function redraw()
  screen.clear()
  if not waveform_loaded then
    screen.level(15)
    screen.move(62,50)
    screen.text_center("Hold K1 to load sample")
  else
    screen.level(4)
    local x_pos = 0
    for i,s in ipairs(waveform_samples) do
      local height = util.round(math.abs(s) * (scale*level))
      screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
    screen.level(15)
    screen.move(util.linlin(0,1,10,120,position),18)
    screen.line_rel(0, 35)
    screen.stroke()
  end
  
  screen.update()
end