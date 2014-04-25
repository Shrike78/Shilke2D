--[[---
Class.lua
Compatible with Lua 5.1 (not 5.0).

Used to implements simple object oriented logic in lua, with single inheritance 
and interface implementation.

@usage

- class can be used to define base classes and derived classes:

A = class()
B = class(A)

b = B()
b:is_a(A) == true
class_type(b) == A -> false
class_type(b) == B -> true

- Multiple inheritance is not allowed, but it's possible to define 
interfaces (always using class) and to require that a class implements them:

iC = class()
D = class(B,iC)

d = D()
d:is_a(A) = true
d:is_a(B) = true
d:is_a(iC) = false
d:is_a(D) = true
d:implements(iC) = true

- It's also possible to implements one or more interfaces without inheritance:

iE = class()
F = class(nil,iC,iE)

f = F()
f:is_a(iC) = false
f:implements(iC) = true
f:implements(iE) = true
--]]


local reserved =
{
    __index		= true,
    _base		= true,
    init		= true,
    is_a		= true,
    implements	= true,
	super		= true			
}


--[[---
Extends the basic lua type keyword, providing a way to check if an obj is also of a given class type.
@param o the object to be testet
@return string/metatable the 'type' of the object, a string for basic lua types or the 
class prototype (aka metatable) for class object instances
@usage
A = class()
B = class(A)

a = A()
b = B()

class_type(a) -> A
class_type(b) -> B
class_type("test") -> 'string'
class_type({1,2,3}) -> 'table'
--]]
function class_type(o)
	local t = type(o)
	if t == 'table' then
		if o.is_a then
			return getmetatable(o)
		end
	end
	return t
end

--[[---
Used to check if a given object is of a given type.
It can be used on generic types and on class object instances
@param o the object to be checked
@param t the type to be checked
@return bool true if the object is of the given type, false if not. 
NB: Even if a class object isntance is always also a table in lua, this function
return false if trying to check a class object instance over a 'table' type.

@usage
A = class()
B = class(A)

a = A()
b = B()

is_a(a,A) -> true
is_a(a,B) -> false

is_a(b,A) -> true
is_a(b,B) -> true

is_a(a,'table') -> false

is_a('test','string') -> true
is_a({1,2,3},'table') -> true

--]]
function is_a(o,t)
	local _t = type(o)
	if _t == 'table' then
		if o.is_a then
			return o:is_a(t)
		end
	end
	return _t == t
end


--[[---
Used to check if a given object implements a given interface.
It can be used on generic types and on class object instances
@param o the object to be checked
@param t the interface type to be checked
@return bool true if the object implements the given interface, false if not. 
NB: we assume that a basic lua object always implements only the interface of its base type

@usage
iA = class()
iB = class()
C = class(nil,iA,iB)

c = C()

implements(c,iA) = true
implements(c,iB) = true
implements(c,C) = true
implements("test",C) = false
implements("test",'string') = true

--]]
function implements(o,t)
	local _t = type(o)
	if _t == 'table' then
		if o.implements then
			return o:implements(t)
		end
	end
	return _t == t
end


--[[---
	Returns the super class of a given class.
	Useful to create polimorfic calls without caring of the actual superclass
	that could change in future
	
	ex:
	
	A = class()
	B = class(A)
	C = class(B)
	o = C()
	
	super(C) -> B
	super(B) -> A
	super(A) -> nil
	
	@param c class
	@return super super class of c (nil if c is a first class)
--]]
function super(c)
	return c._base
end

--[[---
Creates a new class type, allowing single inheritance and multiple interface implementation
@param ... p1 is a base class for inheritance (can be null), following are interface to implement 
--]]
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

	---Allows to check if a class inherits from another
    c.is_a = function(self, klass)
        local m = getmetatable(self)
        while m do 
            if m == klass then return true end
            m = m._base
        end
        return false
    end
    
	---Allows to check if a class implements a specific interface
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