--[[---
Callbacks namespace.
Allows to create a callback object composed by a function and a set of parameters that can
be called lately.
@usage

1) how to wrap a function

function printMsg(msg)
	print(msg)
end

o = Callbacks.callback(printMsg,"prova")
o() -> print "prova"


2) how to wrap a method

A = class()

function A:printMsg(msg)
	print(msg)
end

a = A()

o = Callbacks.callback(A.printMsg,a,"prova")
o() -> print "prova"

--]]
Callbacks = {}

local function callFunction(callback,...)
	return callback(...)    
end

local Callback = class()

---Constructor of the Callback object.
--@param func the function to call back
--@param ... list of parameters (optiona). if func is a method the first parameter must be the
--related object
function Callback:init(func,...)
    self.func = func
    self.args = {...}
    setmetatable(self, { __call = function()
                return callFunction(self.func,unpack(self.args))
            end
        }
    )
end

---Exposed callback method / constructor
Callbacks.callback = Callback