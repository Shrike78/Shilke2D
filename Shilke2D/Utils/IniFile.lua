--[[--- 
Helper to read ini files.
Wraps a table obtained parsing a file ini and exposes functions to easily
access and read data
--]]

IniFile = class()

---Loads a file ini and parse it
--@param fileName the path of the file to load
--@return IniFile object or nil if the path is not valid
--@return nil or error if the path is not valid
function IniFile.fromFile(fileName)
	local t,err = IniParser.parseIniFile(fileName)
	if t then
		return IniFile(t)
	else
		return nil,err
	end
end

---Create a IniFile object starting from text
--@param text the text of 
--@return IniFile object or nil if the path is not valid
--@return nil or error if the path is not valid
function IniFile.fromText(text)
	local t = IniParser.parseIniText(text)
	return IniFile(t)
end


---Constructor
--@param t a table obtained parsing a ini file with IniParser
function IniFile:init(t)
	self.ini = t
end

---Checks section existence
--@param section name of the section
--@return bool
function IniFile:hasSection(section)
	return self.ini[section] ~= nil
end

---Returns a section/key value
--@param section name of the section
--@param key name of the key
--@param default default value to return if section/key has no value. (optional)
--@return string value
function IniFile:getValue(section,key,default)
	if self.ini[section] then
		return self.ini[section][key]
	else
		return default
	end
end


---Returns a section/key value as number
--@param section name of the section
--@param key name of the key
--@param default default value to return if section/key has no value. (optional)
--@return number value
function IniFile:getValueN(section,key,default)
	local v = self:getValue(section,key)
	if v then
		return tonumber(v)
	else
		return default
	end
end

---Returns a section/key value as bool
--@param section name of the section
--@param key name of the key
--@param default default value to return if section/key has no value. (optional)
--@return bool value
function IniFile:getValueBool(section,key,default)
	local v = self:getValue(section,key)
	if v then
		return v:lower() == "true"
	else
		return default
	end
end
