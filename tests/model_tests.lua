package.path = package.path .. ";../?.lua"

luaunit = require("luaunit")
require("model")

TestModel = {}

function TestModel:testSliceStore_thenHasInitialSlices()
    local model = Model:new()
    luaunit.assertEquals(model.sliceStore.sliceTimes[1], 0.0)
    luaunit.assertEquals(model.sliceStore.sliceTimes[2], 1.0)
end

function TestModel:testSliceStore_whenSetLength_thenResetsLengthAndSliceTimes()
    local model = Model:new()
    model.sliceStore:setLength(10.0)
    luaunit.assertEquals(model.sliceStore.length, 10.0)
    luaunit.assertEquals(model.sliceStore.sliceTimes[1], 0.0)
    luaunit.assertEquals(model.sliceStore.sliceTimes[2], 10.0)
end

function TestModel:testSliceStore_whenAddSlice_thenAddsInBetweenInitialSlices()
    local model = Model:new()
    model.sliceStore:addSlice(0.5)
    luaunit.assertEquals(#model.sliceStore.sliceTimes, 3)
    luaunit.assertEquals(model.sliceStore.sliceTimes[1], 0.0)
    luaunit.assertEquals(model.sliceStore.sliceTimes[2], 0.5)
    luaunit.assertEquals(model.sliceStore.sliceTimes[3], 1.0)
end

function TestModel:testSlicesStore_whenAddSliceBeyondLength_thenNoChange()
    local model = Model:new()
    luaunit.assertEquals(#model.sliceStore.sliceTimes, 2)
    model.sliceStore:addSlice(1.2)
    luaunit.assertEquals(#model.sliceStore.sliceTimes, 2)
end

function TestModel:testSlicesStore_whenAddDuplicateSlices_thenNoChange()
    local model = Model:new()
    luaunit.assertEquals(#model.sliceStore.sliceTimes, 2)
    model.sliceStore:addSlice(0.0)
    model.sliceStore:addSlice(1.0)
    luaunit.assertEquals(#model.sliceStore.sliceTimes, 2)
end

function TestModel:testSlicesStore_whenSlicesInRange_thenReturnsSlicesInRange()
    local model = Model:new()
    slicesInRange = model.sliceStore:slicesInRange(0.0, 1.0)
    luaunit.assertEquals(slicesInRange, {0.0, 1.0})
    slicesInRange = model.sliceStore:slicesInRange(0.0, 0.5)
    luaunit.assertEquals(slicesInRange, {0.0})
    slicesInRange = model.sliceStore:slicesInRange(0.5, 1.0)
    luaunit.assertEquals(slicesInRange, {1.0})
end

os.exit( luaunit.LuaUnit.run() )