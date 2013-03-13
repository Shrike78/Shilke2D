-- IniFile

IniFile = class()

function IniFile.fromFile(fileName)
	local t,err = IniParser.parseIniFile(fileName)
	if t then
		return IniFile(t)
	else
		return nil,err
	end
end

function IniFile.fromText(text)
	local t = IniParser.parseIniText(text)
	return IniFile(t)
end

function IniFile:init(t)
	self.ini = t
end

function IniFile:hasSection(section)
	return self.ini[section] ~= nil
end

function IniFile:getValue(section,key,default)
	if self.ini[section] then
		return self.ini[section][key]
	else
		return default
	end
end

function IniFile:getValueN(section,key,default)
	local v = self:getValue(section,key)
	if v then
		return tonumber(v)
	else
		return default
	end
end

function IniFile:getValueBool(section,key,default)
	local v = self:getValue(section,key)
	if v then
		return v:lower() == "true"
	else
		return default
	end
end
