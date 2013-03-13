-- callbacks utilities

Callbacks = {}

--allows to call a specific callback with arguments
function Callbacks.callFunction(callback,...)
	callback(...)
    return
end

local Callback = class()

function Callback:init(func,...)
    self.func = func
    self.args = {...}
    setmetatable(self, { __call = function()
                Callbacks.callFunction(self.func,unpack(self.args))
            end
        }
    )
end

Callbacks.callback = Callback