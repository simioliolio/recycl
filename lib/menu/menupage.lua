require 'util'

MenuPage = {
    page_names = {"no", "pages", "set"},
    selected_page = 1,
    redraw_lock = false,
}

function MenuPage:redraw()
    if self.redraw_lock == true then return end

    screen.clear()

    -- title
    screen.level(15)
    local recycl_text = "Recycl"
    local recycl_text_width, recycl_text_height = screen.text_extents(recycl_text)
    screen.move((128 / 2) - (recycl_text_width / 2), recycl_text_height)
    screen.text(recycl_text)

    -- pages
    local x_pos = 10
    local y_pos = 25
    for i, page_name in ipairs(self.page_names) do
        screen.level(3)
        if i == self.selected_page then
            page_name = "> " .. page_name
            screen.level(15)
        end
        screen.move(x_pos, y_pos)
        screen.text(page_name)
        y_pos = y_pos + 10
    end

    screen.update()
end

function MenuPage:enc(n, d)
    if n == 1 then
        new_page = self.selected_page + d
        self.selected_page = util.clamp(new_page, 1, #self.page_names)
        self:redraw()
    end
end

function MenuPage:key(n, d)
end

return MenuPage