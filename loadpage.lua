fileselect = require 'fileselect'

LoadPage = {
    file = nil,
    file_selected_callback = function(file) end, -- Replace
    redraw_lock = false,
}

function LoadPage:redraw()
    if self.redraw_lock == true then return end

    screen.clear()

    if self.file == nil then
        screen.move(10, 10)
        screen.text("No audio loaded.")
        screen.move(10, 30)
        screen.text("K2: load")

    else
        screen.move(10, 10)
        screen.text("Audio loaded: ")
        screen.move(10, 30)
        screen.text(self.file)
    end
    screen.move(10, 50)
        screen.text("K1 hold: Switch page")
    screen.update()
end

function LoadPage:key(n, z)
    if n == 2 and z == 1 then
        fileselect.enter(os.getenv("HOME").."/dust/audio", function(file)
            if file == "cancel" then return end
            self.file_selected_callback(file)
            self.file = file
            self:redraw()
        end
        )
    end
end

return LoadPage