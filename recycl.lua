fileselect = require 'fileselect'
table = require 'table'
include("waveformdisplay")
include("model")
include("slicepagemode")

SlicePage = require 'recycl/slicepage'
MenuPage = require 'recycl/menupage'

local pages = {SlicePage, MenuPage}
local page_showing = nil

engine.name = "Recycl"


function init()
    show_page(SlicePage)
    SlicePage:init()
end

function show_page(page_to_show)
    page_showing = page_to_show
    for i, page in ipairs(pages) do
        -- page.redraw_lock = (page == page_showing) and false or true
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
        show_page(SlicePage)
        return
    end
    -- send all others to page
    page_showing:key(n, z)
end

function redraw()
    page_showing:redraw()
end