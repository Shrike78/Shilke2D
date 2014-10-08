 --[[---
IniParser allows to parse a ini file and convert it into a lua object,
and offers functionalities to access to section/keys values.

Sections and Keys are case insensitive (and are saved as lower case)
--]]

IniParser = class()

--[[---
Static funtion, used to parse a text representing a ini file

Original parser version used string.match but there were problems 
with iOS version where match failed to return correct results.

@tparam string text the text representing the file ini
@treturn IniParser
--]]
function IniParser.fromText(text)
	local t = {}
	local section
	local _lines = string.split(text,"\n")
	for _,line in pairs(_lines) do
		if not string.starts(line,";") then
			line = string.trim(line)
			if string.starts(line,"[") then
				section = line:sub(2,-2):lower()
				t[section] = t[section] or {}
			end
			local key, value = unpack(string.split(line,"="))
			if key and value then
				t[section][string.trim(key):lower()] = string.trim(value)
			end
		end
	end
	return IniParser(t)
end

--[[---
Static function, used to load a file ini and parse it
@tparam string iniFileName the path of the file ini to load
@treturn[1] IniParser
@return[2] nil
@treturn[2] string error message
--]]
function IniParser.fromFile(iniFileName)
	local iniText, err = IO.getFile(iniFileName)
	if not iniText then
		return nil,err
	end
	return IniParser.fromText(iniText)
end


--[[---
Constructor
@tparam table t a table obtained parsing a ini file with IniParser
--]]
function IniParser:init(t)
	self.ini = t
end


--[[---
Returns a list of available sections.
@treturn {string} sorted list of available sections
--]]
function IniParser:getSections()
	local res = {}
	for k,_ in pairs(self.ini) do
		res[#res+1] = k
	end
	return table.sort(res)
end


--[[---
Checks section existence
@tparam string section name of the section
@treturn bool
--]]
function IniParser:hasSection(section)
	local section = section:lower()
	return self.ini[section] ~= nil
end


--[[---
Adds a section if it doesn't already exist
@tparam string section name of the new section
@treturn bool success
--]]
function IniParser:addSection(section)
	local section = section:lower()
	if self.ini[section] then
		return false
	end
	self.ini[section] = {}
	return true
end


--[[---
removes a given section
@tparam string section name of the section to delete
@treturn bool success
--]]
function IniParser:removeSection(section)
	local section = section:lower()
	if not self.ini[section] then
		return false
	end
	self.ini[section] = nil
	return true
end


--[[---
Returns a list of pairs key/value available in the specified section.
@tparam string section the section to look for 
@return[1] table list of available key/values
@return[2] nil if the section is not valid
--]]
function IniParser:getItems(section)
	local section = section:lower()
	local items = self.ini[section]
	if not items then
		return nil
	end
	return table.copy(items)
end


--[[---
Returns a list of keys available in the specified section.
@tparam string section the section to look for 
@treturn {string} sorted list of available keys
--]]
function IniParser:getKeys(section)
	local section = section:lower()
	local res = {}
	local items = self.ini[section] 
	if items then
		for k,_ in sortedpairs(items) do
			res[#res+1] = k
		end
	end
	return res
end

--[[---
Checks if a key exists
@tparam string section name of the section
@tparam string key name of the key
@treturn bool
--]]
function IniParser:hasKey(section, key)
	local section = section:lower()
	local key = key:lower()
	if self.ini[section] then
		return self.ini[section][key] ~= nil
	end
	return false
end


--[[---
Remove a given key.
@tparam string section
@tparam string key
@treturn bool success
--]]
function IniParser:removeKey(section, key)
	local section = section:lower()
	local key = key:lower()
	local items = self.ini[section]
	if not items or not items[key] then
		return false
	end
	items[key] = nil
	return true
end



--[[---
If the given section exists, set the given option to the specified value. 
Otherwise returns false and does nothing. 
@tparam string section
@tparam string key
@tparam string value
@treturn bool success
--]]
function IniParser:set(section, key, value)
	local section = section:lower()
	local key = key:lower()
	local items = self.ini[section]
	if not items then
		return false
	end
	items[key] = tostring(value)
	return true
end


--[[---
Returns a section/key value as string
@tparam string section name of the section
@tparam string key name of the key
@tparam[opt=nil] string default default value to return if section/key has no value.
@treturn[1] string
@return[2] default
--]]
function IniParser:get(section, key, default)
	local section = section:lower()
	local key = key:lower()
	if not self.ini[section] then
		return default
	end
	return self.ini[section][key] or default
end


--[[---
Returns a section/key value as number
@tparam string section name of the section
@tparam string key name of the key
@tparam[opt=nil] string default default value to return if section/key has no value.
@treturn[1] number
@return[2] default
--]]
function IniParser:getNumber(section, key, default)
	local section = section:lower()
	local key = key:lower()
	local v = self:get(section,key)
	if v then
		return tonumber(v)
	else
		return default
	end
end


--[[---
Returns a section/key value as bool (considered true if the string is 
'true' (no matter the case)
@tparam string section name of the section
@tparam string key name of the key
@tparam[opt=nil] string default default value to return if section/key has no value.
@treturn[1] bool
@return[2] default
--]]
function IniParser:getBool(section, key, default)
	local section = section:lower()
	local key = key:lower()
	local v = self:get(section, key)
	if v then
		return v:lower() == "true"
	else
		return default
	end
end


--[[---
Dump the content to a stringbuilder object
@tparam StringBuilder sb
--]]
function IniParser:dump(sb)
	for section, items in sortedpairs(self.ini) do
		sb:writeln("[" .. section .. "]")
		for k,v in sortedpairs(items) do
			sb:writeln(k.."="..v)
		end
	end
end


--[[---
Return a string with the IniParser content.
Dump the content and flush it on the resulting string
@treturn string
--]]
function IniParser:strDump()
	local sb = StringBuilder()
	self:dump(sb)
	return sb:toString(true)
end


--[[---
Write the content to a file
@tparam string fileName the name of the file to write
@treturn[1] bool success
@return[2] nil
@treturn[2] string error message
--]]
function IniParser:write(fileName)
	local file, err = IO.open(fileName,'w')
	if not file then
		return false, err
	end
	file:write(self:strDump())
	io.close(file)
	return true
end



