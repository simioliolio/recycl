ParamID = include 'recycl/lib/common/paramid'

ParamReg = {}

function ParamReg:addAll()
    params:add_control(ParamID.playback_pitch, "Playback pitch", controlspec.RATE)

    params:add_number(
        ParamID.clock_div,
        "Clock div",
        1,  -- min
        8,  -- max
        2   -- default
    )

    params:add_number(
        ParamID.seq_length,
        "Sequence length",
        1,  -- min
        16,  -- max
        8   -- default
    )
end

return ParamReg