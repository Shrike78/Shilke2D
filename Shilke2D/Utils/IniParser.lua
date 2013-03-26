 --[[---
IniParser allows to parse a file ini and convert it into a lua table.

Original parser version worked with string.match but there were problems 
with iOS version where mathc failed to return correct results.
--]]

IniParser = {}

---Load a file ini and parse it
--@param iniFileName the path of the file ini to load
--@return table with the parsed file info or nil if the path wasn't valid
--@return nil or error if the path wasn't valid
function IniParser.parseIniFile(iniFileName)
    local iniText, err = IO.getFile(iniFileName)
    if (not err) then
        return IniParser.parseIniText(iniText),nil
    else
        return nil,err
    end
end

---Parse a text representing a ini file
--@param text the text representing the file ini
--@return table with the parsed file info
function IniParser.parseIniText(text)
	local t = {}
	local section
	local _lines = string.split(text,"\n")
	for _,line in pairs(_lines) do
		line = string.trim(line)
		if string.starts(line,"[") then
			section = line:sub(2,-2)
			t[section] = t[section] or {}
		end
		local key, value = unpack(string.split(line,"="))
		if key and value then
			t[section][string.trim(key)] = string.trim(value)
		end
	end
	return t
end


