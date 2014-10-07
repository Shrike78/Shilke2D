--[[---
LUA only XmlParser, original code from Alexander Makeev

--]]

XmlParser = {}

--[[---
Converts a string value to an xml string
@param value a generic string
@return string an xml valid string
--]]
function XmlParser.toXmlString(value)
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

--[[---
Converts an xml string to a generic string value
@param value an xml valid string
@return string a generic string
--]]
function XmlParser.fromXmlString(value)
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
   
   
--[[---
Parses a string retrieving a list of arguments as pairs of key/val
@param s a string
@return table a list of key/value pairs
--]]
function XmlParser.parseArgs(s)
    local arg = {}
    --handle space between arguments name, value and "="
	string.gsub(s, "(%S+)[ ]*=[ ]*([\"'])(.-)%2", function (w, _, a)
			arg[w] = XmlParser.fromXmlString(a)
        end)
    return arg
end


--[[---
Parses a xml text and returns a lua table in the form of:
xml = {
	name = "name",
	value = "text",
	attributes = {name = value},
	children = { [...] }
}
@param xmlText the xml to parse
@return table a table containing all the xml infos
--]]
function XmlParser.parseString(xmlText)
    local stack = {}
    local top = {name=nil,value=nil,attributes={},children={}}
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
                top.value=(top.value or "")..XmlParser.fromXmlString(text)
            end  
        end
        if empty == "/" then  
            -- empty element tag
            table.insert(top.children, {name=label,value=nil,
                attributes=XmlParser.parseArgs(xarg),children={}})
        elseif c == "" then   
            -- start tag
            top = {name=label, value=nil, 
                attributes=XmlParser.parseArgs(xarg), children={}}
             -- new level   
            table.insert(stack, top)  
        else  
            -- end tag
            -- remove top
            local toclose = table.remove(stack)  
            top = stack[#stack]
            if #stack < 1 then
                return nil, "XmlParser: nothing to close with "..label
            end
            if toclose.name ~= label then
                return nil, "XmlParser: trying to close ".. toclose.name.." with "..label
            end
            table.insert(top.children, toclose)
        end
        i = j+1
    end
    local text = string.sub(xmlText, i)
    if not string.find(text, "^%s*$") then
        stack[#stack].value=(stack[#stack].value or 
            "")..XmlParser.fromXmlString(text)
    end
    if #stack > 1 then
        return nil, "XmlParser: unclosed "..stack[stack.n].name
    end
    return stack[1].children[1]
end


--[[---
loads a xmlfile and parses it
@return table or nil if an error raises
@return nil or error message if an error raises
--]]
function XmlParser.parseFile(xmlFileName)
	local xmlText, err = IO.getFile(xmlFileName)
	if not xmlText then
		return nil,err
	end
	return XmlParser.parseString(xmlText)
end

