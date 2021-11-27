SliceStore = {
    -- replace with known length so end slice start can be known
    length = 1.0,

    -- add slice start points here
    slice_times = {0.0, 1.0}
}

function SliceStore:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- note; will erase all existing slice times, so best to do this early
function SliceStore:set_length(length)
    self.length = length
    self.slice_times = {0.0, length}
end

function SliceStore:add_slice(intended_slice_start)
    if #self.slice_times < 2 then
        print("not adding slice. slice_times should have at least two slices on init")
        return
    end

    if intended_slice_start >= self.length then
        print("slice not added, goes beyond length")
        return
    end

    local new_slice_times = {}

    for index = 1, #self.slice_times - 1 do
        local index_slice_time = self.slice_times[index]
        table.insert(new_slice_times, index_slice_time)

        local next_index_slice_time = self.slice_times[index + 1]

        -- note; the lack of 'equal to' below prevents duplication
        if index_slice_time < intended_slice_start and
        intended_slice_start < next_index_slice_time then
            table.insert(new_slice_times, intended_slice_start)
        end
    end

    -- add last (not in for loop)
    table.insert(new_slice_times, self.slice_times[#self.slice_times])

    self.slice_times = new_slice_times
end

function SliceStore:slices_in_range(start_time, end_time)
    slices_in_range = {}
    for i, slice_time in ipairs(self.slice_times) do
        if start_time <= slice_time and slice_time <= end_time then
            table.insert(slices_in_range, slice_time)
        end
    end
    return slices_in_range
end

Model = {}

function Model:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.slice_store = SliceStore:new()
    return o
end

return Model