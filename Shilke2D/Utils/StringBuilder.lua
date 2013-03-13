-- StringBuilder

StringBuilder = class()

function StringBuilder:init()
    self.t = {}
    self.len = 0
end

function StringBuilder:reset()
    table.clear(self.t)
    self.len = 0
end

function StringBuilder:write(...)
    local args = {...}
    for i = 1, #args do
        local s = tostring(args[i])
        self.t[#self.t+1] = s
        self.len = self.len + string.len(s)
    end
end

function StringBuilder:writeln(...)
    self:write(...)
    self:write("\n")
end

function StringBuilder:lenght()
    return self.len
end

function StringBuilder:toString(bFlush)
    local s = table.concat(self.t)
    local bFlush = bFlush or false
    if bFlush then
        self:reset()
    end
    return s
end

StringBuilder.__tostring = function(o) return o:toString(true) end