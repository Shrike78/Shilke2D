--[[---

 JSON Encoder and Parser for Lua 5.1
 
 Copyright 2007 Shaun Brown (http://www.chipmunkav.com).
 All Rights Reserved.
 
 Permission is hereby granted, free of charge, to any person 
 obtaining a copy of this software to deal in the Software without 
 restriction, including without limitation the rights to use, 
 copy, modify, merge, publish, distribute, sublicense, and/or 
 sell copies of the Software, and to permit persons to whom the 
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be 
 included in all copies or substantial portions of the Software.
 If you find this software useful please give www.chipmunkav.com a mention.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
 ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

--[[
<ul>
	<li>Encodable Lua types: string, number, boolean, table, nil</li>
	<li>Non Encodable Lua types: function, thread, userdata</li>
	<li>All control chars are encoded to \uXXXX format eg "\021" encodes to "\u0015"</li>
	<li>All Json \uXXXX chars are decoded to chars (0-255 byte range only)</li>
	<li>Json single line // and /* */ block comments are discarded during decoding</li>
	<li>Numerically indexed Lua arrays are encoded to Json Lists eg [1,2,3]</li>
	<li>Lua dictionary tables are converted to Json objects eg {"one":1,"two":2}</li>
<ul>


@usage:

 -- Lua script:
 local t = { 
    ["name1"] = "value1",
    ["name2"] = {1, false, true, 23.54, "a \021 string"}
 }

 local json = Json.encode (t)
 print (json) 
 --> {"name1":"value1","name2":[1,false,true,23.54,"a \u0015 string"]}

 local t = Json.decode(json)
 print(t.name2[4])
 --> 23.54
--]]

local string = string
local math = math
local table = table
local error = error
local tonumber = tonumber
local tostring = tostring
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local assert = assert
local Chipmunk = Chipmunk

---JsonWriter is the helper used to convert a lua object to a string
local JsonWriter = class()

JsonWriter.backslashes = {
        ['\b'] = "\\b",
        ['\t'] = "\\t",    
        ['\n'] = "\\n", 
        ['\f'] = "\\f",
        ['\r'] = "\\r", 
        ['"']  = "\\\"", 
        ['\\'] = "\\\\", 
        ['/']  = "\\/"
    }

function JsonWriter:init()
    self.writer = StringBuilder()
end

function JsonWriter:Append(s)
    self.writer:write(s)
end

function JsonWriter:ToString()
    return self.writer:toString()
end

function JsonWriter:Write(o)
    local t = type(o)
	if t == "boolean" then
        self:WriteString(o)
    elseif t == "number" then
        self:WriteString(o)
    elseif t == "string" then
        self:ParseString(o)
    elseif t == "table" then
        self:WriteTable(o)
	--unsupported lua types	
    elseif t == "function" then
        self:WriteFunction(o)
    elseif t == "thread" then
        self:WriteError(o)
    elseif t == "userdata" then
        self:WriteError(o)
    end
end

function JsonWriter:WriteString(o)
    self:Append(tostring(o))
end

function JsonWriter:ParseString(s)
    self:Append('"')
    self:Append(string.gsub(s, "[%z%c\\\"/]", function(n)
        local c = self.backslashes[n]
        if c then return c end
        return string.format("\\u%.4X", string.byte(n))
    end))
    self:Append('"')
end

function JsonWriter:IsArray(t)
    local count = 0
    local isindex = function(k) 
        if type(k) == "number" and k > 0 then
            if math.floor(k) == k then
                return true
            end
        end
        return false
    end
    for k,v in pairs(t) do
        if not isindex(k) then
            return false, '{', '}'
        else
            count = math.max(count, k)
        end
    end
    return true, '[', ']', count
end


function JsonWriter:WriteTable(t)
    local ba, st, et, n = self:IsArray(t)
    self:Append(st)    
    if ba then        
        for i = 1, n do
            self:Write(t[i])
            if i < n then
                self:Append(',')
            end
        end
    else
        local first = true;
        for k, v in pairs(t) do
			local tc = type(v)
			--skip unsupported types
			if not (tc == "function" or tc == "userdata" or tc == "thread") then
				if not first then
					self:Append(',')
				end
				first = false;            
				self:ParseString(k)
				self:Append(':')
				self:Write(v)            
			end
        end
    end
    self:Append(et)
end


function JsonWriter:WriteFunction(o)
	self:WriteError(o)
end


function JsonWriter:WriteError(o)
    error(string.format(
        "Encoding of %s unsupported", 
        tostring(o)))
end

---JsonReader is the helper used to convert a json string to a lua object
local JsonReader = class()
 
JsonReader.escapes = {
        ['t'] = '\t',
        ['n'] = '\n',
        ['f'] = '\f',
        ['r'] = '\r',
        ['b'] = '\b',
    }

function JsonReader:init(s)
    self.reader = StringReader(s)
end

function JsonReader:Read()
    self:SkipWhiteSpace()
    local peek = self:Peek()
    if peek == nil then
        error(string.format(
            "Nil string: '%s'", 
            self:All()))
    elseif peek == '{' then
        return self:ReadObject()
    elseif peek == '[' then
        return self:ReadArray()
    elseif peek == '"' then
        return self:ReadString()
    elseif string.find(peek, "[%+%-%d]") then
        return self:ReadNumber()
    elseif peek == 't' then
        return self:ReadTrue()
    elseif peek == 'f' then
        return self:ReadFalse()
    elseif peek == '/' then
        self:ReadComment()
        return self:Read()
    else
        error(string.format(
            "Invalid input: '%s'", 
            self:All()))
    end
end
        
function JsonReader:ReadTrue()
    self:TestReservedWord{'t','r','u','e'}
    return true
end

function JsonReader:ReadFalse()
    self:TestReservedWord{'f','a','l','s','e'}
    return false
end

function JsonReader:TestReservedWord(t)
    for i, v in ipairs(t) do
        if self:Next() ~= v then
             error(string.format(
                "Error reading '%s': %s", 
                table.concat(t), 
                self:All()))
        end
    end
end

function JsonReader:ReadNumber()
        local result = self:Next()
        local peek = self:Peek()
        while peek ~= nil and string.find(
        peek, 
        "[%+%-%d%.eE]") do
            result = result .. self:Next()
            peek = self:Peek()
    end
    result = tonumber(result)
    if result == nil then
            error(string.format(
            "Invalid number: '%s'", 
            result))
    else
        return result
    end
end

function JsonReader:ReadString()
    local result = ""
    assert(self:Next() == '"')
        while self:Peek() ~= '"' do
        local ch = self:Next()
        if ch == '\\' then
            ch = self:Next()
            if self.escapes[ch] then
                ch = self.escapes[ch]
            end
        end
                result = result .. ch
    end
        assert(self:Next() == '"')
    local fromunicode = function(m)
        return string.char(tonumber(m, 16))
    end
    return string.gsub(
        result, 
        "u%x%x(%x%x)", 
        fromunicode)
end

function JsonReader:ReadComment()
        assert(self:Next() == '/')
        local second = self:Next()
        if second == '/' then
            self:ReadSingleLineComment()
        elseif second == '*' then
            self:ReadBlockComment()
        else
            error(string.format(
        "Invalid comment: %s", 
        self:All()))
    end
end

function JsonReader:ReadBlockComment()
    local done = false
    while not done do
        local ch = self:Next()        
        if ch == '*' and self:Peek() == '/' then
            done = true
                end
        if not done and 
            ch == '/' and 
            self:Peek() == "*" then
                    error(string.format(
            "Invalid comment: %s, '/*' illegal.",  
            self:All()))
        end
    end
    self:Next()
end

function JsonReader:ReadSingleLineComment()
    local ch = self:Next()
    while ch ~= '\r' and ch ~= '\n' do
        ch = self:Next()
    end
end

function JsonReader:ReadArray()
    local result = {}
    assert(self:Next() == '[')
    local done = false
    if self:Peek() == ']' then
        done = true;
    end
    while not done do
        local item = self:Read()
        result[#result+1] = item
        self:SkipWhiteSpace()
        if self:Peek() == ']' then
            done = true
        end
        if not done then
            local ch = self:Next()
            if ch ~= ',' then
                error(string.format(
                    "Invalid array: '%s' due to: '%s'", 
                    self:All(), ch))
            end
        end
    end
    assert(']' == self:Next())
    return result
end

function JsonReader:ReadObject()
    local result = {}
    assert(self:Next() == '{')
    local done = false
    if self:Peek() == '}' then
        done = true
    end
    while not done do
        local key = self:Read()
        if type(key) ~= "string" then
            error(string.format(
                "Invalid non-string object key: %s", 
                key))
        end
        self:SkipWhiteSpace()
        local ch = self:Next()
        if ch ~= ':' then
            error(string.format(
                "Invalid object: '%s' due to: '%s'", 
                self:All(), 
                ch))
        end
        self:SkipWhiteSpace()
        local val = self:Read()
        result[key] = val
        self:SkipWhiteSpace()
        if self:Peek() == '}' then
            done = true
        end
        if not done then
            ch = self:Next()
                    if ch ~= ',' then
                error(string.format(
                    "Invalid array: '%s' near: '%s'", 
                    self:All(), 
                    ch))
            end
        end
    end
    assert(self:Next() == "}")
    return result
end

function JsonReader:SkipWhiteSpace()
    local p = self:Peek()
    while p ~= nil and string.find(p, "[%s/]") do
        if p == '/' then
            self:ReadComment()
        else
            self:Next()
        end
        p = self:Peek()
    end
end

function JsonReader:Peek()
    return self.reader:peek()
end

function JsonReader:Next()
    return self.reader:next()
end

function JsonReader:All()
    return self.reader:all()
end


Json = {}

--[[
Encodes a lua table into a json string
@param t the lua table to encode
@return string the encoded json string
--]]
function Json.encode(t)
	local writer = JsonWriter()
	writer:Write(t)
	return writer:ToString()
end

--[[
Decodes a json string converting into a lua object
@param s the json string to decode
@return table a lua object
--]]
function Json.decode(s)
	local reader = JsonReader(s)
	return reader:Read()
end