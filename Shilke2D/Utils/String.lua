-- string utilities functions extension

function string.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function string.starts(s,startString)
   return string.sub(s,1,string.len(startString))==startString
end

function string.ends(s,endString)
   return string.sub(s,-string.len(endString))==endString
end

function string.removePrefix(s, prefix)
	if string.starts(s,prefix) then
		return string.sub(s,string.len(prefix)+1)
	end
	return s
end

function string.removeSuffix(s, suffix)
	if string.ends(s,suffix) then
		return string.sub(s,1,-string.len(suffix)-1)
	end
	return s
end

function string.split(s,re)
    local i1 = 1
    local ls = {}
    local append = table.insert
    -- if no separator is provided, it uses spaces and return an array
    -- with all the words of "s"
    if not re then 
        re = '%s+' 
    end
    if re == '' then return {s} end
        while true do
            local i2,i3 = s:find(re,i1)
            if not i2 then
                local last = s:sub(i1)
                if last ~= '' then append(ls,last) end
                if #ls == 1 and ls[1] == '' then
                    return {}
                else
                    return ls
            end
        end
        append(ls,s:sub(i1,i2-1))
        i1 = i3+1
    end
end

--return path, filename, extension
function string.splitPath(path)
	return string.match(path, "(.-)([^\\]-)%.([^%.]+)$")
end

function string.getFileExtension(path)
	return string.match(path, "([^%.]+)$")
end

function string.getFileDir(path)
	return string.match(path, "(.-)[^\\/]-[^%.]+$")
end

--withExtension is optional. if not provided return fileName without extension
function string.getFileName(path,withExtension)
	if withExtension then
		return string.match(path, "([^\\/]-[^%.]+)$")
	else
		return string.match(path, "([^\\/]+)%..*$")
	end
end
