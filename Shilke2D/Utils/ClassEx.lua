-- Class.lua
-- Compatible with Lua 5.1 (not 5.0).

--[[ 
class(ancestor, interfaces...)

examples:
- class(base) 
inherits from base, so is_a(base) is true

class(base, interface1,..,interfacen)
inheriths from base and implements all the interfaces, so
is_a is true only for base, while implements is true for all the interfaces, and also for base


class(nil, interface1,..,interfacen)

implements interfaces but without inheritance, so is_a is true only for self name and i plements is true for all the interfaces


pay attention to symbol redefinition. in init phase a warning is logged when a symbol is redefined but no more
--]]

local reserved =
{
    __index            = true,
    _base              = true,
    init               = true,
    is_a               = true,
    implements         = true
}

function class_type(o)
	local t = type(o)
	if t ~= 'table' then return nil end
	return getmetatable(o)
end

function class(...)
    
    local c = {}    -- a new class instance

    local args = {...}
    if table.getn(args) then
        
        local base = args and args[1] or nil
        
        if type(base) == 'table' then
            -- our new class is a shallow copy of the base class!
            for i,v in pairs(base) do
                c[i] = v
            end
            c._base = base
        end
        
        table.remove(args,1)
        
        for _,i in pairs(args) do
            if type(i) =='table' then
                for k,v in pairs(i) do
                    if not reserved[k] and type(i[k]) == 'function' then
                        if c[k] then
                            print("warning " .. k .. 
                                " is already defined")
                        end
                        c[k] = v
                    end
                end
            end
        end
    end    

    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>( <args> )
    local mt = {}
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj,c)
        if class_tbl.init then
            class_tbl.init(obj,...)
        else 
            -- make sure that any stuff from the base class is 
            --initialized!
            if base and base.init then
                base.init(obj, ...)
            end
        end

        return obj
    end

    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do 
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    
    c.implements = function(self, interface)
            -- Check we have all the target's callables
        for k, v in pairs(interface) do
            if not reserved[k] and type(v) == 'function' and 
                type(self[k]) ~= 'function' then
                return false
            end
        end
        return true
    end

    setmetatable(c, mt)
    return c
end