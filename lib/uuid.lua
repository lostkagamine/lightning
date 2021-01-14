local rand = math.random
local fmt = string.format

local function uuid()
    local field1 = fmt("%08x", rand(0, 0xFFFFFFFF))
    local field2 = fmt("%04x", rand(0, 0xFFFF))
    local field3 = fmt("1%03x", rand(0, 0xFFF))
    local field4 = fmt("4%03x", rand(0, 0xFFF))
    local field5 = fmt("%08x%04x", rand(0, 0xFFFFFFFF), rand(0, 0xFFFF))

    return fmt("%s-%s-%s-%s-%s", field1, field2, field3, field4, field5)
end

return uuid
