 --[[---
IniParser allows to parse a ini file and convert it into a lua object,
and offers functionalities to access to section/keys values.
--]]

IniParser = class()

--[[---
Static funtion, used to parse a text representing a ini file

Original parser version used string.match but there were problems 
with iOS version where match failed to return correct results.

@param text the text representing the file ini
@return IniParser with the parsed file info
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
@param iniFileName the path of the file ini to load
@return IniParser or nil if the path is not valid or the file is not a valid ini file
@return nil or error if the path wasn't valid
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
@param t a table obtained parsing a ini file with IniParser
--]]
function IniParser:init(t)
	self.ini = t
end


--[[---
Returns a list of available sections.
@return table list of available sections
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
@param section name of the section
@return bool
--]]
function IniParser:hasSection(section)
	local section = section:lower()
	return self.ini[section] ~= nil
end


--[[---
Adds a section if it doesn't already exist
@param section name of the new section
@return bool success
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
@param section name of the section to delete
@return bool success
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
@param section the section to look for 
@return table list of available key/values
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
@param section the section to look for 
@return table list of available keys
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
@param section name of the section
@param key name of the key
@return bool
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
@param section
@param key
@param value
@return bool success
--]]
function IniParser:removeKey(section, key, value)
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
@param section
@param key
@param value
@return bool success
--]]
function IniParser:set(section, key, value)
	local section = section:lower()
	local key = key:lower()
	local items = self.ini[section]
	if not items then
		return false
	end
	items[key] = tostring(value)
end


--[[---
Returns a section/key value as string
@param section name of the section
@param key name of the key
@param default[opt] default value to return if section/key has no value.
@return string value
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
@param section name of the section
@param key name of the key
@param default[opt] default value to return if section/key has no value.
@return number value
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
@param section name of the section
@param key name of the key
@param default[opt] default value to return if section/key has no value.
@return bool value
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
Dump the content to a string
@return string
--]]
function IniParser:dump()
	local sb = StringBuilder()
	for section, items in sortedpairs(self.ini) do
		sb:writeln("[" .. section .. "]")
		for k,v in sortedpairs(items) do
			sb:writeln(k.."="..v)
		end
	end
	return sb:toString(true)
end


--[[---
Write the content to a file
@param fileName the name of the file to write
@return bool success
--]]
function IniParser:write(fileName)
	local file, err = IO.open(fileName,'w')
	if not file then
		return false, err
	end
	file:write(self:dump())
	io.close(file)
	return true
end



