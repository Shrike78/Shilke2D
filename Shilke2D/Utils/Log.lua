--[[---
Log class extends StringBuilder and allows to log multiple messages in memory and print the result
only at the end. That allows to raise performances in debug.
--]]
Log = class(StringBuilder)

function Log:init()
    StringBuilder.init(self)
end

---Write a message
--@param ... each param is converted to a string and appended to the string builder
function Log:write(...)
    local args = {...}
    for i = 1, #args do
        if i ~= 1 then
            StringBuilder.write(self, "\t")
        end
        StringBuilder.write(self,args[i])
    end
end

---print the result using outFunc
--@param bFlush bool, if true clears the builder
--@param outFunc function used to print the log. default value is "print"
function Log:print(bFlush,outFunc)
    local outFunc = outFunc or print
    outFunc(self:toString(bFlush))
end
