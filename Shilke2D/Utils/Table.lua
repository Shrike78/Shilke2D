-- table utilities functions extension
        
function table.clear(t)
    for k,_ in pairs(t) do
        t[k] = nil
    end
end  

function table.copy(t)
    local u ={}
    for k,v in pairs(t) do
        u[k] = v
    end
    return setmetatable(u, getmetatable(t))
end

function table.deepcopy(t)
    if type(t) ~= 'table' then 
        return t 
    end
    local mt = getmetatable(t)
    local res = {}
    for k,v in pairs(t) do
        if type(v) == 'table' then
            res[k] = table.deepcopy(v)
        else
            res[k] = v
        end
    end
    setmetatable(res,mt)
    return res
end 

function table.removeKey(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

function table.find(t,o)
    local c = 1
    for _,v in pairs(t) do
        if(v == o) then
            return c
        end
        c = c + 1
    end
    return 0
end

function table.removeObj(t, o)
    local i = table.find(t,o)
    if i then 
        return table.remove(t,i)
    end
    return nil
end


function table.invert(t)
    local new = {}
    for i=0, #t do
        table.insert(new, t[#t - i])
    end
    return new
end

function table.slice(t,i1,i2)
    local res = {}
    local n = #t
    -- default values for range
    local i1 = i1 or 1
    local i2 = i2 or n
    if i2 < 0 then
        i2 = n + i2 + 1
    elseif i2 > n then
        i2 = n
    end
    if i1 < 1 or i1 > n then
        return {}
    end
    local k = 1
    for i = i1,i2 do
        res[k] = t[i]
    k = k + 1
    end
    return res
end

function table.dump(t)
	for k,v in pairs(t) do
		print(k,v)
		if type(v) == "table" then
			table.dump(v)
		end
	end
end
    