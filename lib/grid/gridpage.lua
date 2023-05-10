OnScreenGrid = include 'recycl/lib/grid/onscreengrid'

GridPage = {
    redraw_lock = false,
}

-- private

local function grid_redraw_clock(self)
    while true do
      clock.sleep(1/30)
      if not self.redraw_lock then
        self:scheduled_redraw()
      end
    end
end

-- public

function GridPage:init()
    self.clockid = clock.run(function() grid_redraw_clock(self) end)
end

function GridPage:key(n,z)
    OnScreenGrid:key(n,z)
end

function GridPage:enc(n,d)
    OnScreenGrid:enc(n,d)
end

function GridPage:redraw()
    OnScreenGrid:display_render()
end

function GridPage:scheduled_redraw()
    if OnScreenGrid.dirty_screen then
        OnScreenGrid:display_render()
    end
end


return GridPage