package.path = package.path .. ";../?.lua"

luaunit = require("luaunit")
require("model")

TestModel = {}

function TestModel:test_sliceStore_thenHasInitialSlices()
    local model = Model:new()
    luaunit.assertEquals(model.slice_store.slice_times[1], 0.0)
    luaunit.assertEquals(model.slice_store.slice_times[2], 1.0)
end

function TestModel:test_sliceStore_whenSetLength_thenResetsLengthAndSliceTimes()
    local model = Model:new()
    model.slice_store:set_length(10.0)
    luaunit.assertEquals(model.slice_store.length, 10.0)
    luaunit.assertEquals(model.slice_store.slice_times[1], 0.0)
    luaunit.assertEquals(model.slice_store.slice_times[2], 10.0)
end

function TestModel:test_sliceStore_whenAddSlice_thenAddsInBetweenInitialSlices()
    local model = Model:new()
    model.slice_store:add_slice(0.5)
    luaunit.assertEquals(#model.slice_store.slice_times, 3)
    luaunit.assertEquals(model.slice_store.slice_times[1], 0.0)
    luaunit.assertEquals(model.slice_store.slice_times[2], 0.5)
    luaunit.assertEquals(model.slice_store.slice_times[3], 1.0)
end

function TestModel:test_slicesStore_whenAddSliceBeyondLength_thenNoChange()
    local model = Model:new()
    luaunit.assertEquals(#model.slice_store.slice_times, 2)
    model.slice_store:add_slice(1.2)
    luaunit.assertEquals(#model.slice_store.slice_times, 2)
end

function TestModel:test_sliceStore_whenRemoveMiddleSlice_thenRemovesSlice()
    local model = Model:new()
    model.slice_store.slice_times = {0.0, 0.5, 1.0}
    model.slice_store:remove_slice(2)
    luaunit.assertEquals(model.slice_store.slice_times, {0.0, 1.0})
end

function TestModel:test_sliceStore_whenRemoveSlice_thenDoesNotRemoveFirstOrLast()
    local model = Model:new()
    model.slice_store.slice_times = {0.0, 0.5, 1.0}
    model.slice_store:remove_slice(1)
    model.slice_store:remove_slice(3)
    luaunit.assertEquals(model.slice_store.slice_times, {0.0, 0.5, 1.0})
end

function TestModel:test_slicesStore_whenAddDuplicateSlices_thenNoChange()
    local model = Model:new()
    luaunit.assertEquals(#model.slice_store.slice_times, 2)
    model.slice_store:add_slice(0.0)
    model.slice_store:add_slice(1.0)
    luaunit.assertEquals(#model.slice_store.slice_times, 2)
end

function TestModel:test_slicesStore_whenSlicesInRange_thenReturnsSlicesInRange()
    local model = Model:new()
    slices_in_range = model.slice_store:slices_in_range(0.0, 1.0)
    luaunit.assertEquals(slices_in_range, {0.0, 1.0})
    slices_in_range = model.slice_store:slices_in_range(0.0, 0.5)
    luaunit.assertEquals(slices_in_range, {0.0})
    slices_in_range = model.slice_store:slices_in_range(0.5, 1.0)
    luaunit.assertEquals(slices_in_range, {1.0})
end

function TestModel:test_sliceStore_whenClosestSliceIndex_thenReturnsClosestSlice()
    local model = Model:new()
    model.slice_store.slice_times = {0.0, 0.5, 1.0}
    local closest_slice = model.slice_store:closest_slice_index(0.4)
    luaunit.assertEquals(closest_slice, 2)
end

function TestModel:test_sliceStore_whenClosestSliceIndexStart_thenReturnsClosestSlice()
    local model = Model:new()
    model.slice_store.slice_times = {0.0, 0.5, 1.0}
    local closest_slice = model.slice_store:closest_slice_index(0.0)
    luaunit.assertEquals(closest_slice, 1)
end

function TestModel:test_sliceStore_whenClosestSliceIndexEnd_thenReturnsClosestSlice()
    local model = Model:new()
    model.slice_store.slice_times = {0.0, 0.5, 1.0}
    local closest_slice = model.slice_store:closest_slice_index(1.0)
    luaunit.assertEquals(closest_slice, 3)
end

os.exit( luaunit.LuaUnit.run() )