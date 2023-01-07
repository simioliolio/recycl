-- Use this to host a particular page which is under development
-- (ie, host the menu page for faster iteration on the UI, without having to
-- interact with norns to see the menu page)

table = require 'table'
include("waveformdisplay")
include("model")
include("slicepagemode")

MenuPage = include("menupage")
LoadPage = include("loadpage")
SlicePage = include("slicepage")

local all_pages = {MenuPage, LoadPage, SlicePage}
local page_showing = nil

engine.name = "Recycl"


function init()
    setup_pages()
end

function setup_pages()

    -- ! Uncomment appropriate `show_page` call for page currently under development !

    MenuPage.page_names = { "load", "slice" }
    MenuPage.selected_page = 1
    -- show_page(MenuPage)

    LoadPage.file = nil
    show_page(LoadPage)

    SlicePage.debug_mode = true -- TODO: Pass in init
    SlicePage:init()
    -- show_page(SlicePage)
end

function show_page(page_to_show)
    page_showing = page_to_show
    for i, page in ipairs(all_pages) do
        if page == page_showing then
            page.redraw_lock = false
        else
            page.redraw_lock = true
        end
    end
    page_showing:redraw()
end

function enc(n, d)
    if page_is_showing() then page_showing:enc(n, d) end
end

function key(n, z)
    if page_is_showing() then page_showing:key(n, z) end
end

function redraw()
    if page_is_showing() then page_showing:redraw() end
end

function page_is_showing()
    if not page_showing then
        print("Error! No hosted page!");
        return false
    else
        return true
    end
end