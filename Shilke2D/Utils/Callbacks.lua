--[[---
Callback class allows to create an object composed by a function with a predefined set of parameters 
that can be called lately. The callback is generated using a clusure so the value of provided 
parameters is the one they have at callback creation. Obviously for table and classes 'value'
refers to the reference to the data, not to the content.

A differente set of params can be then provided at call time. This set of params is placed after 
the set of parameters registered at callback creation.

That allows for example to register an object method as callback function for a callback with arguments.

@usage
1) how to wrap a function

function printMsg(msg)
	print(msg)
end

--the argument of the registered callback function is stored at creation time
o = Callback(printMsg,"test")
o() 
>test

--the argument of the registered callback function is provided at call time
o = Callback(printMsg)
o("test") 
>test


2) how to wrap a method

A = class()

function A:printMsg(msg)
	print(msg)
end

a = A()

--the argument of the registered callback method is stored at creation time
o = Callback(A.printMsg,a,"test")
o()
>test

--the argument of the registered callback method is provided at call time
o = Callback(A.printMsg,a)
o("test")
>test


3) mixed arguments:

function formatMsg(format, ...)
	return string.format(format, ...)
end

pairFormatter = Callback(formatMsg,"value: (%d,%d)")
print(pairFormatter(2,3))
>value: (2,3)
--]]

Callback = class()

---Constructor of the Callback object.
--@param func the function to call back
--@param ... list of parameters (optiona). if func is a method the first parameter must be the
--related object
function Callback:init(func,...)
	assert(is_function(func))
    self.func = func
    self.args = {...}
	local mt = getmetatable(self)
	mt.__call = function(self, ...)
		local args = {...}
		local t = nil
		if #args > 0 then
			t = table.copy(self.args)
			table.extend(t,args)
		else
			t = self.args
		end
		return self.func(unpack(t))
	end
end


--[[---
check if a given object can be considered as a function. returns true if the object
is a function, a Callback or any table with a __call function defined in the metatable
@param f the object to be test as a function
@treturn boolean true if the object is a function or anyway if a __call metavalue is defined
--]]
function is_function(f)
	local t = class_type(f) 
	if t == 'function' or t == Callback then
		return true
	end
	local mt = getmetatable(f)
	if mt and mt.__call then
		return true
	end
	return false
end
