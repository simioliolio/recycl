table = require 'table'
include("waveformdisplay")
include("model")
include("slicepagemode")
fileselect = require 'fileselect'

MenuPage = require 'recycl/menupage'
-- Use MenuPage to access other pages...
LoadPage = require 'recycl/loadpage'
SlicePage = require 'recycl/slicepage'

local all_pages = {MenuPage, LoadPage, SlicePage}
local pages_via_menu = {LoadPage, SlicePage}
local page_showing = nil

engine.name = "Recycl"


function init()
    setup_pages()
    SlicePage.debug_mode = false -- TODO: Make as part of init
    SlicePage:init()
end

function setup_pages()
    MenuPage.page_names = { "load", "slice" }
    local starting_page = 1
    MenuPage.selected_page = starting_page
    LoadPage.file_selected_callback = function(file)
        SlicePage:load_file(file)
    end
    LoadPage.file = nil
    show_page(pages_via_menu[starting_page])
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
    page_showing:enc(n, d)
end

function key(n, z)
    -- intercept k1
    if n == 1 and z == 1 then
        show_page(MenuPage)
        return
    elseif n == 1 and z == 0 then
        local page = pages_via_menu[MenuPage.selected_page]
        show_page(page)
        return
    end
    -- send all others to page
    page_showing:key(n, z)
end

function redraw()
    page_showing:redraw()
end