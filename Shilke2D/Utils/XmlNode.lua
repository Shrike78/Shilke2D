--[[---
XmlNode is an helper class to work with xmls.
A XmlNode object has a name, a value, attributes, children nodes and a father.
An XmlNode without a father is a root node.
It's possible to convert product of XmlParser into an XmlNode.
It's also possible to add / remove children and attributes from a node.
--]]
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
@param xml a xml lua table obtained by XmlParser.parse
@param parent[opt], if provided the new node is attached to the parent node
@return XmlNode
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
@param xml the xml string to use for creating the node structure
@param parent[opt], if provided the new node is attached to the parent node
@return XmlNode
@return err nil or error if xml text provided was not valid
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
@param fileName the name of the xml file to parse
@param parent[opt], if provided the new node is attached to the parent node
@return XmlNode
@return err nil or error if file was not correctly loaded
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
@param child the XmlNode to attach as a child
--]]
function XmlNode:addChild(child)
    table.insert(self.children,child)
	child.parent = self
end


--[[---
Removes a child from the current XmlNode
@param child the XmlNode to remove from children list
@return XmlNode if the node was really a child it returns it, else returns nil
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
@param name attribute name
@param value attribute value
--]]
function XmlNode:addAttribute(name,value)
	if self.attributes then
        self.attributes[name] = tostring(value)
    end
end


--[[---
Removes an attribute
@param name the name of the attribute to remove
@return value of the removed attribute or nil if the attribute is not a valid one
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
@param name attribute key
@param default[opt] if the attribute doesn't exist returns it. default value is nil
@return string the value of the attribute as a string or nil 
--]]
function XmlNode:getAttribute(name, default)
    if self.attributes and self.attributes[name] then
        return self.attributes[name]
    end
    return default
end


--[[---
Returns an attribute value converted as number. 
@param name attribute key
@param default[opt] if the attribute doesn't exist returns it. default value is nil
@return int the value of the attribute as a int or nil 
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
@param name attribute key
@param default[opt] if the attribute doesn't exist returns it. default value is nil
@return bool the value of the attribute as a bool or nil 
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
@param idx the index of the attribute
@return string the name of the attribute if idx is a valid index, or nil
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
@return int number of attributes
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
@param name[opt] the name of the children element we want to retrieve. 
If not provided the method returns all the children of the node
@return XmlNode[] an ordered array of all the children with the given name
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


--[[---Returns the parent node
@return XmlNode the parent node
--]]
function XmlNode:getParent()
    return self.parent
end


--[[---
Dumps xmlnode content over a StringBuilder
@param sb a StringBuilder object
@param tab the number of '\t' required to format the output
--]]
function XmlNode:dump(sb, tab)
	
	local function addTab(sb, tab)
		if tab>0 then
			for i=0,tab-1,1 do
				sb:write('\t')
			end
		end
	end
	
	local tab = tab or 0
	if tab > 0 then
		sb:writeln()
	end
	addTab(sb,tab)
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
		addTab(sb,tab)
	end
	sb:write("</" .. self.name .. ">")
end


--[[---
Prints the content of an XmlNode
@return string
--]]
function XmlNode:strDump()
	local sb = StringBuilder()
	self:dump(sb)
    return sb:toString(true)
end


--[[---
Write the content to a file
@param fileName the name of the file to write
@return bool success
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
