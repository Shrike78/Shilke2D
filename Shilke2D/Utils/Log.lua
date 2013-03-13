-- Log

Log = class(StringBuilder)

function Log:init()
    StringBuilder.init(self)
end

function Log:write(...)
    local args = {...}
    for i = 1, #args do
        if i ~= 1 then
            StringBuilder.write(self, "\t")
        end
        StringBuilder.write(self,args[i])
    end
end

function Log:print(bFlush,outFunc)
    
    local outFunc = outFunc or print
    outFunc(self:toString(bFlush))
end