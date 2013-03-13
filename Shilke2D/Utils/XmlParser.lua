-- LUA only XmlParser, original code from Alexander Makeev

XmlParser = {}

function XmlParser.ToXmlString(value)
    value = string.gsub (value, "&", "&amp;");        -- '&' -> "&amp;"
    value = string.gsub (value, "<", "&lt;");        -- '<' -> "&lt;"
    value = string.gsub (value, ">", "&gt;");        -- '>' -> "&gt;"
    --value = string.gsub (value, "'", "&apos;");    -- '\'' -> "&apos;"
    value = string.gsub (value, "\"", "&quot;");    -- '"' -> "&quot;"
    -- replace non printable char -> "&#xD;"
    value = string.gsub(value, "([^%w%&%;%p%\t% ])",
        function (c) 
            return string.format("&#x%X;", string.byte(c)) 
            --return string.format("&#x%02X;", string.byte(c)) 
            --return string.format("&#%02d;", string.byte(c)) 
        end)
    return value
end

function XmlParser.FromXmlString(value)
    value = string.gsub(value, "&#x([%x]+)%;",
        function(h) 
            return string.char(tonumber(h,16)) 
        end)
    value = string.gsub(value, "&#([0-9]+)%;",
        function(h) 
            return string.char(tonumber(h,10)) 
        end)
    value = string.gsub (value, "&quot;", "\"")
    value = string.gsub (value, "&apos;", "'")
    value = string.gsub (value, "&gt;", ">")
    value = string.gsub (value, "&lt;", "<")
    value = string.gsub (value, "&amp;", "&")
    --value = string.gsub (value, "\t", "")
    
    --removes extra space from beginning (leave 0 spaces) and in
    --the middle of the string (leave one space)
    value = string.gsub (value, "^%s+", "")
    value = string.gsub (value, "%s+", " ")
    return value
end
   
function XmlParser.ParseArgs(s)
    local arg = {}
    --handle space between arguments name, value and "="
	string.gsub(s, "(%S+)[ ]*=[ ]*([\"'])(.-)%2", function (w, _, a)
			arg[w] = XmlParser.FromXmlString(a)
        end)
    return arg
end

function XmlParser.ParseXmlText(xmlText)
    local stack = {}
    local top = {name=nil,value=nil,attributes={},childNodes={}}
    table.insert(stack, top)
    local ni,c,label,xarg, empty
    local i, j = 1, 1
    while true do
        ni,j,c,label,xarg, empty = string.find(xmlText, 
			"<(%/?)([%w:%_]+)(.-)(%/?)>", i)
        if not ni then 
            break 
        end
        local text = string.sub(xmlText, i, ni-1)
        if not string.find(text, "^%s*$") then
            --avoid comments and commands
            if not string.find(text, "^[ ]*[\t]*[\n]*<") then
                top.value=(top.value or "")..XmlParser.FromXmlString(text)
            end  
        end
        if empty == "/" then  
            -- empty element tag
            table.insert(top.childNodes, {name=label,value=nil,
                attributes=XmlParser.ParseArgs(xarg),childNodes={}})
        elseif c == "" then   
            -- start tag
            top = {name=label, value=nil, 
                attributes=XmlParser.ParseArgs(xarg), childNodes={}}
             -- new level   
            table.insert(stack, top)  
        else  
            -- end tag
            -- remove top
            local toclose = table.remove(stack)  
            top = stack[#stack]
            if #stack < 1 then
                error("XmlParser: nothing to close with "..label)
            end
            if toclose.name ~= label then
                error("XmlParser: trying to close "..
                    toclose.name.." with "..label)
            end
            table.insert(top.childNodes, toclose)
        end
        i = j+1
    end
    local text = string.sub(xmlText, i)
    if not string.find(text, "^%s*$") then
        stack[#stack].value=(stack[#stack].value or 
            "")..XmlParser.FromXmlString(text)
    end
    if #stack > 1 then
        error("XmlParser: unclosed "..stack[stack.n].name)
    end
    return stack[1].childNodes[1]
end

function XmlParser.ParseXmlFile(xmlFileName)
    local xmlText, err = IO.getFile(xmlFileName)
    if (not err) then
        return XmlParser.ParseXmlText(xmlText),nil
    else
        return nil,err
    end
end

--print plain text value
function XmlParser.dump(xml,log)
    --local xml
    if xml.name then 
        log:writeln(xml.name) 
    end
    if xml.value then
        log:writeln(xml.value)
    end
    if xml.attributes then
        for i,v in pairs(xml.attributes) do
            log:writeln(i,v)
        end
    end
    if xml.childNodes then
        for _,child in pairs(xml.childNodes) do
            if type(child) == 'table' then
                XmlParser.dump(child,log)
            end
        end
    end
end
