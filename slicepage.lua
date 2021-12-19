table = require 'table'
require("util")
include("waveformdisplay")
include("model")
include("slicepagemode")

SlicePage = {
  debug_mode = true,
  debug_file = "/home/we/dust/audio/common/The Breaks/11thhouse.wav",
  level = 1.0,
  length = 1,
  waveform_loaded = false,
  mode = SlicePageMode.SLICE_SET,
  waveform_display = WaveformDisplay:new(),
  model = Model:new(),
  -- waveform view
  cursor_position_time = 0,
  selected_slice_index = 1,
  no_slice_selected = true,
  scale = 30, -- TODO: Rename
  redraw_lock = false,
}

function SlicePage:init()
  self:setup_softcut()
  self:register_playhead_poll()
  self:reset()
  if self.debug_mode then self:load_file(self.debug_file) end
end

function SlicePage:setup_softcut()
  softcut.buffer_clear()
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)
  softcut.phase_quant(1,0.01)
  softcut.poll_start_phase()
  softcut.event_render(self.on_render)
end

function SlicePage:register_playhead_poll()
  self.playhead_poll = poll.set('playhead', function(pos)
    self.playhead_position = pos
    self:redraw()
  end)
  self.playhead_poll.time = 0.1
end

function SlicePage:reset()
  for i=1,2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(1,1.0)
    softcut.position(i,0)
    softcut.rate(i,1.0)
    softcut.fade_time(1,0)
  end
  self.cursor_position_time = 0
  self.waveform_display = WaveformDisplay:new(
    {update_data_request = self.update_content,
    max_render_duration = self.length}
  )
  self.model = Model:new()
  self.model.slice_store:set_length(self.length)
  self.playhead_position = nil
  -- trigger intial waveform load
  self.update_content(self.waveform_display.render_time_start, self.waveform_display.render_duration)
end

  --/ startup

  -- file loading

function SlicePage:load_file(file)
  softcut.buffer_clear_region(1,-1)
  self.selecting_file = false
  if file ~= "cancel" then
    local ch, samples = audio.file_info(file)
    self.length = samples / 48000 -- shouldn't hard code?
    softcut.buffer_read_mono(file,0,0,-1,1,1) -- only split mono for now?
    softcut.buffer_read_mono(file,0,0,-1,1,2) --
    engine.load_audio_file(file)
    self:reset()
    self.waveform_loaded = true
  end
end

--/ file loading


-- softcut render event callback
-- FIXME: Is there a way of using `:` / `self` here?
function SlicePage.on_render(ch, start, i, s)
  SlicePage.waveform_display:set_waveform_data(i, s)
  SlicePage:redraw()
end

-- trigger render event
-- FIXME: Is there a way of using `:` / `self` here?
function SlicePage.update_content(winstart,duration)
  softcut.render_buffer(1, util.clamp(winstart, 0.0, SlicePage.length), duration, SlicePage.waveform_display.render_width)
end

--/ waveform view

-- user input

function SlicePage:key(n,z)
  if n==2 and z==1 then
    if self.mode == SlicePageMode.SLICE_SET then
      self.model.slice_store:add_slice(self.cursor_position_time)
      self.selected_slice_index = self.model.slice_store:closest_slice_index(self.cursor_position_time)
      self:redraw()
    elseif self.mode == SlicePageMode.SLICE_REVIEW then
      self.model.slice_store:remove_slice(self.selected_slice_index)
      self.no_slice_selected = true
      self:redraw()
    end

  elseif n==3 and z==1 then
    engine.play(self.cursor_position_time / self.length)
    self.playhead_poll:start()
  elseif n==3 and z==0 then
    engine.stop()
    self.playhead_poll:stop()
    self.playhead_position = nil
    self:redraw()
  end
end

function SlicePage:enc(n,d)
  if n==1 then
    self.waveform_display:zoom(d)
  elseif n==2 then
  -- move cursor along waveform
    self.mode = SlicePageMode.SLICE_SET
    local jump = self.waveform_display.render_duration / self.waveform_display.render_width -- jump approx 1 pixel
    local cursor_offset = jump * d -- neg or pos offset depending on enc turn direction
    self.cursor_position_time = util.clamp(self.cursor_position_time + cursor_offset, 0.0, self.length)
    self.no_slice_selected = true
    self.waveform_display:set_center_and_update(self.cursor_position_time)
  elseif n==3 then
    -- move cursor to a slice
    if self.no_slice_selected then
      -- FIXME: use d to either get 'first_slice_after_(time)' or 'first_slice_before_(time)' and remove 'closest...' if not in use
      self.selected_slice_index = self.model.slice_store:closest_slice_index(self.cursor_position_time)
      self.no_slice_selected = false
    else
      local current_number_of_slice_times = #self.model.slice_store.slice_times
      self.selected_slice_index = util.clamp(self.selected_slice_index + d, 1, current_number_of_slice_times)
    end
    self.mode = SlicePageMode.SLICE_REVIEW
    self.cursor_position_time = self.model.slice_store.slice_times[self.selected_slice_index]
    self.waveform_display:set_center_and_update(self.cursor_position_time)
  end
end

--/ user input

-- screen drawing

function SlicePage:redraw()
  if self.redraw_lock == true then return end
  screen.clear()
  if not self.waveform_loaded then
  -- show loading dialog
    screen.level(15)
    screen.move(64,25)
    screen.text_center("No sample loaded!")
    screen.move(64,45)
    screen.text_center("Hold K1, goto 'load' page")
  else
  -- draw waveform
    screen.level(4)
    local x_pos = 0
    for i,s in ipairs(self.waveform_display.samples) do
      local height = util.round(math.abs(s) * (self.scale*self.level))
      screen.move(util.linlin(0,self.waveform_display.render_width,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
  -- draw cursor position
    local start_time = self.waveform_display.render_time_start
    local end_time = start_time + self.waveform_display.render_duration
    screen.level(15)
    screen.move(util.linlin(start_time,end_time,10,120,self.cursor_position_time),18)
    screen.line_rel(0, 35)
    screen.stroke()
  -- draw playhead
    if (self.playhead_position ~= nil) and (self.playhead_position < end_time) then
      screen.level(2)
      screen.move(util.linlin(start_time, end_time, 10, 120, self.playhead_position), 0)
      screen.line_rel(0, 64)
      screen.stroke()
    end
  -- draw slice times
    local slice_times_to_display = self.model.slice_store:slices_in_range(start_time, end_time)
    for i, sliceTime in ipairs(slice_times_to_display) do
      screen.level(5)
      local slice_x_pos = util.linlin(start_time, end_time, 10, 120, sliceTime)
      screen.move(slice_x_pos, 4)
      screen.line_rel(0, 60)
      screen.stroke()
      screen.circle(slice_x_pos, 4, 2)
      screen.stroke()
    end
  -- draw text
    local play_text = "K3: play"
    local play_text_width, play_text_height = screen.text_extents(play_text)
    screen.move(120 - play_text_width, 62)
    screen.text(play_text)
    if self.mode == SlicePageMode.SLICE_SET then
      screen.move(0, 62)
      screen.text("K2: add")
      screen.move(0, 0 + play_text_height)
      screen.text(string.format("%.2f", self.cursor_position_time))
    elseif self.mode == SlicePageMode.SLICE_REVIEW then
      screen.move(0, 62)
      screen.text("K2: del")
      screen.move(0, 0 + play_text_height)
      screen.text(self.selected_slice_index .. "/" .. #self.model.slice_store.slice_times)
    end

  end

  screen.update()
end

--/ screen drawing


-- Standalone
-- (load this script on norns to work solely on this page)
print("Setting Recycl engine in slicepage")
engine.name = "Recycl"

function init()
  print("slice.lua init")
  SlicePage:init()
end

function enc(n, d)
  SlicePage:enc(n, d)
end

function key(n, z)
  SlicePage:key(n, z)
end

--/ Standalone

return SlicePage