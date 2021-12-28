package.path = package.path .. ";../?.lua" .. ";../../?.lua"

luaunit = require("luaunit")

GridViewModel = require("gridviewmodel")

TestGridViewModel = {}

function TestGridViewModel:test_init_thenCurrentVisibleStepIsNil()
    local sut = GridViewModel:new()
    luaunit.assertNil(sut.current_visible_step)
end

function TestGridViewModel:test_updateCurrentVisibleStep_whenIsValid_thenUpdatesCurrentVisibleStep()
    local sut = GridViewModel:new()
    sut:update_current_visible_step(2)
    luaunit.assertEquals(sut.current_visible_step, 2)
end

os.exit( luaunit.LuaUnit.run() )