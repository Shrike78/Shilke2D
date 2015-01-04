--[[---
XmlNode is an helper class to work with xmls.
A XmlNode object has a name, a value, attributes, children nodes and a father.
An XmlNode without a father is a root node.
It's possible to convert product of XmlParser into an XmlNode.
It's also possible to add / remove children and attributes from a node.
--]]

require("Shilke2D/Utils/Config/Externals/XmlParser")


XmlNode = class()


---Constructor.
function XmlNode:init(name,attributes,value,children)
    self.name = name
    self.value = value
    self.attributes = attributes or {}
    self.children = children or {}
	self.parent = nil
end

--[[---
Creates a XmlNode starting from the product of XmlParser.parse. 
Attaches the new xmlNode to "parent"
@tparam table xml a xml lua table obtained by XmlParser.parse
@tparam[opt=nil] XmlNode parent if provided the new node is attached to the parent node
@treturn XmlNode node
--]]
function XmlNode.fromLuaXml(xml, parent)    
    local node = XmlNode(xml.name, xml.attributes, xml.value)  
	if parent then
		parent:addChild(node)
	end
    if xml.children then
        for _,child in pairs(xml.children) do
            childNode = XmlNode.fromLuaXml(child,node)
        end 
    end
    return node
end


--[[---
Builds an XmlNode starting from a string.
Uses XmlParser.parseString to easily load the string
@tparam string xml the xml string to use for creating the node structure
@tparam[opt=nil] XmlNode parent if provided the new node is attached to the parent node
@treturn[1] XmlNode node the newly created node 
@return[2] nil
@treturn[2] string error message
--]]
function XmlNode.fromString(xml, parent)
	local luaXml, err = XmlParser.parseString(xml)
	if not luaXml then
		return nil, err
	end
	local xmlNode = XmlNode.fromLuaXml(luaXml,parent)
	return xmlNode
end


--[[---
Builds an XmlNode starting from a file.
Uses XmlParser.parseFile to easily load the file
@tparam string fileName the name of the xml file to parse
@tparam[opt=nil] XmlNode parent if provided the new node is attached to the parent node
@treturn[1] XmlNode node
@return[2] nil
@treturn[2] string error message
--]]
function XmlNode.fromFile(fileName, parent)
	local luaXml, err = XmlParser.parseFile(fileName)
	if not luaXml then
		return nil, err
	end
	local xmlNode = XmlNode.fromLuaXml(luaXml, parent)
	return xmlNode
end

--[[---
Adds a child to the current XmlNode
@tparam XmlNode child the XmlNode to attach as a child
@treturn XmlNode return a reference to the added node
--]]
function XmlNode:addChild(child)
    table.insert(self.children,child)
	child.parent = self
	return child
end


--[[---
Removes a child from the current XmlNode
@tparam XmlNode child the XmlNode to remove from children list
@treturn[1] XmlNode the removed child
@return[2] nil if child was not in node children
--]]
function XmlNode:removeChild(child)
	local res = table.removeObj(self.children,child)
	if res then
		res.parent = nil
	end
	return res
end


--[[---
Adds a new attribute
if the attribute was already defined it replaces the attribute value
@tparam string name attribute name
@tparam string value attribute value
--]]
function XmlNode:addAttribute(name,value)
	if self.attributes then
        self.attributes[name] = tostring(value)
    end
end


--[[---
Removes an attribute
@tparam string name the name of the attribute to remove
@treturn[1] string value of the removed attribute 
@return[2] nil if name is not a valid node attribute
--]]
function XmlNode:removeAttribute(name)
	if self.attributes then
        local value = self.attributes[name]
		self.attributes[name] = nil
		return value
    end
    return nil
end


--[[---
Returns the value of an attribute
@tparam string name attribute key
@tparam[opt=nil] string default if the attribute doesn't exist returns it.
@treturn[1] string the value of the attribute as a string
@return[2] default 
--]]
function XmlNode:getAttribute(name, default)
    if self.attributes and self.attributes[name] then
        return self.attributes[name]
    end
    return default
end


--[[---
Returns an attribute value converted as number. 
@tparam string name attribute key
@param[opt=nil] default if the attribute doesn't exist returns it.
@treturn[1] number the value of the attribute as a number
@return[2] default 
--]]
function XmlNode:getAttributeAsNumber(name, default)
	local v = self:getAttribute(name)
	if v then
		return tonumber(v)
	else
		return default
	end
end

--[[---
Returns an attribute value converted as boolean. 
@tparam string name attribute key
@param[opt=nil] default if the attribute doesn't exist returns it. default value is nil
@treturn[1] bool the value of the attribute as a bool
@return[2] default
--]]
function XmlNode:getAttributeAsBool(name, default)
	local v = self:getAttribute(name)
	if v then
		return v:lower() == "true"
	else
		return default
	end
end


--[[---
Returns the attribute name of attribute number 'idx'
@tparam number idx the index of the attribute
@treturn[1] string the name of the attribute if idx is a valid index
@return[2]	nil
--]]
function XmlNode:getAttributeName(idx)
    local i=1
    for k,_ in pairs(self.attributes) do
        if i == idx then
            return k
        end
        i = i + 1
    end
	return nil
end


--[[---
Returns the number of attributes
@treturn int number of attributes
--]]
function XmlNode:getNumAttributes()
    local i=0
    for _,_ in pairs(self.attributes) do
        i = i + 1
    end
    return i
end


--[[---
Returns a children list of child with a given name
@tparam[opt=nil] string name the name of the children element we want to retrieve. 
If not provided the method returns all the children of the node
@treturn {XmlNode} an ordered array of all the children with the given name
--]]
function XmlNode:getChildren(name)
    if not name then
        return self.children
    else
        local tmp = {}
        for _,child in pairs(self.children) do
            if child.name and child.name == name then
                table.insert(tmp,child)
            end
        end
        return tmp
    end
end


--[[---
Returns the parent node
@treturn XmlNode the parent node
--]]
function XmlNode:getParent()
    return self.parent
end


--[[---
Dumps xmlnode content over a StringBuilder
@tparam StringBuilder sb
@tparam number tab the number of '\t' required to format the output
--]]
function XmlNode:dump(sb, tab)
	
	local tab = tab or 0
	if tab > 0 then
		sb:writeln()
	end
	for i=0,tab-1,1 do
		sb:write('\t')
	end
	sb:write("<" .. self.name)
	for k,v in pairs(self.attributes) do
		sb:write(" " .. k .. '="' .. XmlParser.toXmlString(v) .. '"')
	end
	sb:write(">")
	if self.value then
		sb:write(XmlParser.toXmlString(self.value))
	end
	local bNewLine = false
	for _,v in pairs(self.children) do
		v:dump(sb, tab+1)
		bNewLine = true
	end
	if bNewLine then
		sb:writeln()
		for i=0,tab-1,1 do
			sb:write('\t')
		end
	end
	sb:write("</" .. self.name .. ">")
end


--[[---
Prints the content of an XmlNode
@treturn string
--]]
function XmlNode:strDump()
	local sb = StringBuilder()
	self:dump(sb)
    return sb:toString(true)
end


--[[---
Write the content to a file
@tparam string fileName the name of the file to write
@treturn[1] bool success
@return[2] nil
@treturn[2] string error message
--]]
function XmlNode:write(fileName)
	local file, err = IO.open(fileName,'w')
	if not file then
		return false, err
	end
	file:write('<?xml version="1.0" encoding="UTF-8"?>\n')
	file:write(self:strDump())
	io.close(file)
	return true
end
