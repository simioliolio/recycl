fileselect = require 'fileselect'
table = require 'table'
include("waveformdisplay")
include("model")
include("slicepagemode")

SlicePage = require 'recycl/slicepage'

engine.name = "Recycl"

function init()
    SlicePage:init()
end

function enc(n, d)
    SlicePage:enc(n, d)
end

function key(n, z)
    SlicePage:key(n, z)
end