-- Use this to host a particular page which is under development
-- (ie, host the menu page for faster iteration on the UI, without having to
-- interact with norns to see the menu page)

table = require 'table'
include("slice/waveformdisplay")
include("slice/model")
include("slice/slicepagemode")
Grid = include("grid/grid")
GridSequencerModel = include 'recycl/lib/grid/gridsequencermodel'
SequencePlayer = include 'recycl/lib/common/sequenceplayer'
ParamReg = include 'recycl/lib/common/paramreg'
SequencerParams = include 'recycl/lib/common/sequencerparams'

MenuPage = include("menu/menupage")
LoadPage = include("load/loadpage")
SlicePage = include("slice/slicepage")
GridPage = include("grid/gridpage")

local all_pages = {MenuPage, LoadPage, SlicePage, GridPage}
local page_showing = nil

engine.name = "Recycl"


function init()
    ParamReg:addAll()
    setup_pages()
    SequencePlayer.connect_sequencer_to_slice_player()
    SequencerParams.connect()
end

function setup_pages()

    grid_base = Grid:new()

    -- ! Uncomment appropriate `show_page` call for page currently under development !

    MenuPage.page_names = { "load", "slice" }
    MenuPage.selected_page = 1
    -- show_page(MenuPage)

    LoadPage.file = nil
    -- show_page(LoadPage)

    SlicePage.debug_mode = true -- TODO: Pass in init
    SlicePage:init()

    GridPage:init()

    show_page(GridPage)
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