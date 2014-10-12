--[[---
Base class that allows to parse a string, a character at once

@todo missing features to behave like a file
--]]
StringReader = class()

--[[---
costructor, initializes with a string
@tparam string s
--]]
function StringReader:init(s)
	self.s = s or ""
	self.i = 0   
end

--[[---
Gets next character without moving the position
@treturn string next char
--]]
function StringReader:peek()
    local i = self.i + 1
    if i <= #self.s then
        return string.sub(self.s, i, i)
    end
    return nil
end

--[[---
Gets next character, moving the position
@treturn string next char
--]]
function StringReader:next()
    self.i = self.i+1
    if self.i <= #self.s then
        return string.sub(self.s, self.i, self.i)
    end
    return nil
end

--[[---
Gets the whole string
@treturn string
--]]
function StringReader:all()
    return self.s
end