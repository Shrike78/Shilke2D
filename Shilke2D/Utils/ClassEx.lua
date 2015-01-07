--[[---
Compatible with Lua 5.1 (not 5.0).

Used to implement simple object oriented logic in lua, with single inheritance 
and interface implementation.

It's possible to test instances of classes to check type and inheritance using class_type(),
implements() and is_a() functions

It's also possible to create particular classes having as instances MOAI objects 
incapsulated into a full lua class hierarchy. It's so possible to extend moai 
objects adding custom lua support.

Object created this way are at the same time lua class instances and MOAIObj instances (userdata).


The MOAI_class implementation is based on makotok flower library
(https://github.com/makotok/Hanappe)

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
d:is_a(A) -> true
d:is_a(B) -> true
d:is_a(iC) -> false
d:is_a(D) -> true
d:implements(iC) -> true

- It's also possible to implements one or more interfaces without inheritance:

iE = class()
F = class(nil,iC,iE)

f = F()
f:is_a(iC) -> false
f:implements(iC) -> true
f:implements(iE) -> true


G = MOAI_class(MOAIProp,F)
g = G()
type(g) -> userdata (MOAIProp)
class_type(g) == G -> true
g:is_a(G) -> true
g:is_a(F) -> true
g:implements(iE) -> true

g:setLoc(0,0,0) -> it works because g is at the same time a G instance and a MOAIProp instance

--]]


local reserved =
{
    __index	 = true,
	__moai_class = true,
	__moai_interface = true,
	__interface = true,
    __super = true,
    init = true,
    is_a = true,
    implements = true			
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
	if (t == 'table' or t == 'userdata') and o.is_a then
		return o.__interface.__index
	end
	return t
end

--[[---
Used to check if a given object is of a given type.
It can be used on generic types and on class object instances
@param o the object to be checked
@param t the type to be checked
@return bool true if the object is of the given type, false if not. 
NB: Even if a class object instance is always also a table in lua, this function
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
	if (_t == 'table' or t == 'userdata') and o.is_a then
		return o:is_a(t)
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

implements(c,iA) -> true
implements(c,iB) -> true
implements(c,C) -> true
implements("test",C) -> false
implements("test",'string') -> true

--]]
function implements(o,t)
	local _t = type(o)
	if (_t == 'table' or t == 'userdata') and o.implements then
		return o:implements(t)
	end
	return _t == t
end


--[[---
Returns the super class of a given class / class instance.
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
super(o) -> B

@param c class or class instance
@return super super class of c (nil if c is a first class)
--]]
function super(c)
	return c.__super
end


---
-- Creates a new class type, allowing single inheritance and multiple interface implementation
-- @param ... p1 is a base class for inheritance (can be null), following are interface to implement 
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
            c.__super = base
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

	-- create an interface table that will be the metatable for all the 
	-- class objects (and for itself too).
	-- The interface uses the class as __index, so the objects
	-- will look up their methods in it
	c.__interface = c
	-- the class has itself as index. That allows normal class objects to 
	-- correctly handle metaclass functions, like operators.
	c.__index = c
	
    -- expose a constructor which can be called by <classname>( <args> )
    local mt = {}
    mt.__call = function(class_tbl, ...)
		local obj
		--
		if c.__moai_class then
			-- create a new object of moai class type
			obj = c.__moai_class.new()
			-- set class interface as lua interface for moai objects 
			obj:setInterface(c.__interface)
		else
			-- set class interface as metatable of new objects
			obj = {}
			-- uses interface as metatable of the newly created obj
			setmetatable(obj,c.__interface)
		end
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

	---
	-- Allows to check if a class inherits from another
    c.is_a = function(self, klass)
		local m = self.__interface.__index
        while m do
            if m == klass then 
				return true 
			end
            m = m.__super
        end
        return false
    end
    
	--- 
	-- Allows to check if a class implements a specific interface
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
	
	-- inherits moaiinterface from parent if a new MOAI_class is not used
 	if c.__moai_class then
		-- mt is metatable of c. Setting the interfacetable of  
		-- moai_class as __index of mt allows class to lookup for 
		-- moai_class interfaceTable methods
		mt.__index = c.__moai_class.getInterfaceTable()
	end
    setmetatable(c, mt)
    return c
end


---
-- Creates a new class type, allowing single inheritance and multiple interface implementation
-- Instances of the new class are not tables but MOAI objects with a given interface table. 
-- The extended class version supports inheritance and all the other class functionalities,
-- except for metatable functions (like operators) that are not correctly handled.
-- @param moaiType MOAI class type 
-- @param ... p1 is a base class for inheritance (can be null), following are interfaces to implement 
function MOAI_class(moaiType, ...)
	local c = class(...)
	c.__moai_class = moaiType
	-- set moai class interfacetable as __index of class metatable
	local t = getmetatable(c)
	t.__index = moaiType.getInterfaceTable()
	--set moai interface as class property in order to have faster access
	c.__moai_interface = t.__index
	setmetatable(c,t)
	return c
end


--[[---
Returns the moai interface of the given moai class / moai class instance
Usefull expecially when a lua class overrides a moai interface method

@usage
A = class(MOAIProp)
a = A()
moai_interface(A).setLoc(a,x,y) -> a:setLoc(x,y)
moai_interface(a).setLoc(a,x,y) -> a:setLoc(x,y)

It's also possible to use directly inner __moai_interface class property:

a.__moai_interface.setLoc(a,x,y)-> a:setLoc(x,y)

@param c moai_class or moai_class instance 
@return[1] the moai interface of the given class / class instance. 
@return[2] nil if the object is not a MOAI_class instance 
--]]
function moai_interface(c)
	return c.__moai_interface
end

---
-- Utility function. can be used in debugger to inspect
-- MOAI_class objects. It shows the lua members of the 
-- given obj
-- @param o a MOAI_class instance
function membertable(o)
	if type(o) == 'userdata' and o.is_a then
		-- this works on all moai version. 
		-- After v1_5_1 it's possible to use getmetatable(getmetatable(o))
		return getmetatable(o).__index
	else
		return tostring(q) .. " is not a valid MOAI_class"
	end
end


--- 
-- Utility function. can be used in debugger to inspect
-- MOAI_class objects. It shows the lua interface of the 
-- given obj
-- @param o a MOAI_class instance
function interfacetable(o)
	if type(o) == 'userdata' and o.is_a then
		return getmetatable(getmetatable(getmetatable(o)))
	else
		return tostring(q) .. " is not a valid MOAI_class"
	end
end


---
-- Utility function. Can be used to check if a lua class override 
-- moai interface methods.
function check_moai_class(c)
	for k,v in pairs(c) do
		if type(v) == 'function' then
			if c.__moai_class.getInterfaceTable()[k] then
				print('WARNING',k,'alread defined')
			end
		end
	end
end

