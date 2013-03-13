-- IniParser

IniParser = {}

function IniParser.parseIniFile(iniFileName)
    local iniText, err = IO.getFile(iniFileName)
    if (not err) then
        return IniParser.parseIniText(iniText),nil
    else
        return nil,err
    end
end

--original version worked with string.match but there were problems with iOS version where mathc
--failed to return correct results.
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


