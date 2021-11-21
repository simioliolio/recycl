SliceStore = {
    -- replace with known length so end slice start can be known
    length = 1.0,

    -- add slice start points here
    sliceTimes = {0.0, 1.0} 
}

function SliceStore:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- note; will erase all existing slice times, so best to do this early
function SliceStore:setLength(length)
    self.length = length
    self.sliceTimes = {0.0, length}
end

function SliceStore:addSlice(intendedSliceStart)
    if #self.sliceTimes < 2 then 
        print("not adding slice. sliceTimes should have at least two slices on init")
        return
    end

    if intendedSliceStart >= self.length then
        print("slice not added, goes beyond length")
        return
    end

    local newSliceTimes = {}

    for index = 1, #self.sliceTimes - 1 do
        indexSliceTime = self.sliceTimes[index]
        table.insert(newSliceTimes, indexSliceTime)

        nextIndexSliceTime = self.sliceTimes[index + 1]

        -- note; the lack of 'equal to' below prevents duplication
        if indexSliceTime < intendedSliceStart and 
        intendedSliceStart < nextIndexSliceTime then
            table.insert(newSliceTimes, intendedSliceStart)
        end
    end

    -- add last (not in for loop)
    table.insert(newSliceTimes, self.sliceTimes[#self.sliceTimes])

    self.sliceTimes = newSliceTimes
end

function SliceStore:slicesInRange(startTime, endTime)
    slicesInRange = {}
    for i, sliceTime in ipairs(self.sliceTimes) do
        if startTime <= sliceTime and sliceTime <= endTime then
            table.insert(slicesInRange, sliceTime)
        end
    end
    return slicesInRange
end

Model = {}

function Model:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.sliceStore = SliceStore:new()
    return o
end

return Model