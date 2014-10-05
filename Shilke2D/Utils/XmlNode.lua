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
    self.childNodes = children or {}
	self.parent = nil
end

---Creates a XmlNode starting from the product of XmlParser.parse. 
--Attaches the new xmlNode to "parent"
--@param xml a xml lua table obtained by XmlParser.parse
--@param parent optional, if provided the new node is attached to the parent node
--@return XmlNode
function XmlNode.fromLuaXml(xml,parent)    
    local node = XmlNode(xml.name, xml.attributes, xml.value)  
	if parent then
		parent:addChild(node)
	end
    if xml.childNodes then
        for _,child in pairs(xml.childNodes) do
            childNode = XmlNode.fromLuaXml(child,node)
        end 
    end
    return node
end


---Builds an XmlNode starting from a string.
--Uses XmlParser.ParseXmlText to easily load the string
--@param xml the xml string to use for creating the node structure
--@param parent optional, if provided the new node is attached to the parent node
--@return XmlNode
function XmlNode.fromString(xml,parent)
    local luaXml = XmlParser.ParseXmlText(xml)
    local xmlNode = XmlNode.fromLuaXml(luaXml,parent)
    return xmlNode
end

---Adds a child to the current XmlNode
--@param child the XmlNode to attach as a child
function XmlNode:addChild(child)
    table.insert(self.childNodes,child)
	child.parent = self
end

---Removes a child from the current XmlNode
--@param child the XmlNode to remove from children list
--@return XmlNode if the node was really a child it returns it, else returns nil
function XmlNode:removeChild(child)
	local res = table.removeObj(self.childNodes,child)
	if res then
		res.parent = nil
	end
	return res
end

---Returns the value of an attribute
--@param name attribute key
--@param default [optional] if the attribute doesn't exist returns it. default value is nil
--@return string the value of the attribute as a string or nil 
function XmlNode:getAttribute(name, default)
    if self.attributes and self.attributes[name] then
        return self.attributes[name]
    end
    return default
end

---Adds a new attribute
--if the attribute was already defined it replaces the attribute value
--@param name attribute name
--@param value attribute value
function XmlNode:addAttribute(name,value)
	if self.attributes then
        self.attributes[name] = value
    end
end

---Removes an attribute
--@param name the name of the attribute to remove
--@return value of the removed attribute or nil if the attribute is not a valid one
function XmlNode:removeAttribute(name)
	if self.attributes then
        local value = self.attributes[name]
		self.attributes[name] = nil
		return value
    end
    return nil
end

---Returns an attribute value converted as number. 
--@param name attribute key
--@param default [optional] if the attribute doesn't exist returns it. default value is nil
--@return int the value of the attribute as a int or nil 
function XmlNode:getAttributeNumber(name, default)
	local v = self:getAttribute(name)
	if v then
		return tonumber(v)
	else
		return default
	end
end

---Returns an attribute value converted as boolean. 
--@param name attribute key
--@param default [optional] if the attribute doesn't exist returns it. default value is nil
--@return bool the value of the attribute as a bool or nil 
function XmlNode:getAttributeBool(name, default)
	local v = self:getAttribute(name)
	if v then
		return v:lower() == "true"
	else
		return default
	end
end

---Returns the attribute name of attribute number 'idx'
--@param idx the index of the attribute
--@return string the name of the attribute if idx is a valid index, or nil
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

---Returns the number of attributes
--@return int number of attributes
function XmlNode:getNumAttributes()
    local i=0
    for _,_ in pairs(self.attributes) do
        i = i + 1
    end
    return i
end

---Returns a children list of child with a given name
--@param name [optional] the name of the children element we want to retrieve. 
--If not provided the method returns all the children of the node
--@return XmlNode[] an ordered array of all the children with the given name
function XmlNode:getChildren(name)
    if not name then
        return self.childNodes
    else
        local tmp = {}
        for _,child in pairs(self.childNodes) do
            if child.name and child.name == name then
                table.insert(tmp,child)
            end
        end
        return tmp
    end
end

---Returns the parent node
--@return XmlNode the parent node
function XmlNode:getParent()
    return self.parent
end

---Dumps xmlnode content over a StringBuilder
--@param stringbuilder the StringBuilder o use to dump the content of the node
function XmlNode:dump(stringbuilder)
    stringbuilder:writeln(self.name)
    if self.value then 
        stringbuilder:writeln(self.value)
    end
    for i,v in pairs(self.attributes) do
        stringbuilder:writeln(i.." = "..v)
    end
    for _,xmlNode in pairs(self:getChildren()) do
        xmlNode:dump(stringbuilder)
    end
end

---Prints the content of an XmlNode
--@return string
function XmlNode:strDump()
	local sb = StringBuilder()
	self:dump(sb)
    return sb:toString(true)
end

--[[
XmlNode.__tostring = function(o) 
    return o:strDump()
end
--]]    

--[[
function XmlNode:toStr(indent,tagValue)
  local indent = indent or 0
  local indentStr=""
  for i = 1,indent do indentStr=indentStr.."  " end
  local tableStr=""
  
  if base.type(var)=="table" then
    local tag = var[0] or tagValue or base.type(var)
    local s = indentStr.."<"..tag
    for k,v in base.pairs(var) do -- attributes 
      if base.type(k)=="string" then
        if base.type(v)=="table" and k~="_M" then --  otherwise recursiveness imminent
          tableStr = tableStr..str(v,indent+1,k)
        else
          s = s.." "..k.."=\""..encode(base.tostring(v)).."\""
        end
      end
    end
    if #var==0 and #tableStr==0 then
      s = s.." />\n"
    elseif #var==1 and base.type(var[1])~="table" and #tableStr==0 then -- single element
      s = s..">"..encode(base.tostring(var[1])).."</"..tag..">\n"
    else
      s = s..">\n"
      for k,v in base.ipairs(var) do -- elements
        if base.type(v)=="string" then
          s = s..indentStr.."  "..encode(v).." \n"
        else
          s = s..str(v,indent+1)
        end
      end
      s=s..tableStr..indentStr.."</"..tag..">\n"
    end
    return s
  else
    local tag = base.type(var)
    return indentStr.."<"..tag.."> "..encode(base.tostring(var)).." </"..tag..">\n"
  end
end
--]]
