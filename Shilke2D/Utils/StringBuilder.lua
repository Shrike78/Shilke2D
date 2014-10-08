--[[---
StringBuilder class to enable faster string composition
--]]
StringBuilder = class()

function StringBuilder:init()
    self.t = {}
    self.len = 0
end

---Resets the builder data
function StringBuilder:reset()
    table.clear(self.t)
    self.len = 0
end

--[[---Appends a set of stringified items
@param ... each param is converted calling tostring() and is 
appended to the inner string list
--]]
function StringBuilder:write(...)
    local args = {...}
    for i = 1, #args do
        local s = tostring(args[i])
        self.t[#self.t+1] = s
        self.len = self.len + string.len(s)
    end
end

---Calls write(...) and append a 'newline' at the end
function StringBuilder:writeln(...)
    self:write(...)
    self:write("\n")
end

--[[---
Returns the length of the final string.
The value is updated each time a new
string is added to the builder
@return number
--]]
function StringBuilder:lenght()
    return self.len
end

--[[---
Returns the resulting string and, if bFlush is true,
resets the builder
@param bFlush bool, if true clear the builder
@return string
--]]
function StringBuilder:toString(bFlush)
    local s = table.concat(self.t)
    local bFlush = bFlush == true
    if bFlush then
        self:reset()
    end
    return s
end

---returns the current string value without flushing the builder
StringBuilder.__tostring = function(o) return o:toString(false) end