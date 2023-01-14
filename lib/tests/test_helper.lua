-- Expose lua files to 'require'
package.path = package.path .. ";../?.lua" .. ";../../?.lua"

-- 'include' is a norns thing. 'require' is the correct Lua way.
-- 'require' means restarting norns whenever a change is made (due to the 'module'
-- being reloaded). Therefore recycl code uses 'include' in most places.
-- This breaks tests, because 'include' is undefined. Therefore, 'include'
-- is bridged to 'require' here.
function include(file)
    return require(file)
end