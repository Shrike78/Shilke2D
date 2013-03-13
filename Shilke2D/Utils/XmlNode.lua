-- XmlNode

XmlNode = class()

function XmlNode:init(name,attributes,value,children,parent)
    self.name = name
    self.value = value
    self.parent = parent
    self.attributes = attributes or {}
    self.childNodes = children or {}
end

function XmlNode.fromLuaXml(xml,parent)    
    local node = XmlNode(xml.name,xml.attributes,
        xml.value,nil,parent)  
    if xml.childNodes then
        for _,child in pairs(xml.childNodes) do
            childNode = XmlNode.fromLuaXml(child,node)
            node:addChild(childNode)
        end 
    end
    return node
end

function XmlNode.fromString(xml)
    local luaXml = XmlParser.ParseXmlText(xml)
    local xmlNode = XmlNode.fromLuaXml(luaXml)
    return xmlNode
end

function XmlNode:addChild(child)
    table.insert(self.childNodes,child)
end

function XmlNode:removeChild(child)
	return table.removeObj(self.childNodes,child)
end

function XmlNode:getAttribute(name, default)
    if self.attributes and self.attributes[name] then
        return self.attributes[name]
    end
    return default
end

function XmlNode:removeAttribute(name)
	if self.attributes then
        local value = self.attributes[name]
		self.attributes[name] = nil
		return value
    end
    return nil
end

--return a number attribute already converted as number. If attribute doesn't exist
--it return default value (if provided, or nil if not)
function XmlNode:getAttributeN(name, default)
	local v = self:getAttribute(name)
	if v then
		return tonumber(v)
	else
		return default
	end
end

--return a boolean attribute converted as true/false. If attribute doesn't exist
--it return default value (if provided, or nil if not)
--it expected
function XmlNode:getAttributeBool(name, default)
	local v = self:getAttribute(name)
	if v then
		return v:lower() == "true"
	else
		return default
	end
end

function XmlNode:getAttributeName(idx)
    local i=1
    for k,_ in pairs(self.attributes) do
        if i == idx then
            return k
        end
        i = i + 1
    end
end

function XmlNode:getNumAttributes()
    local i=0
    for _,_ in pairs(self.attributes) do
        i = i + 1
    end
    return i
end

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

function XmlNode:getParent()
    return self.parent
end

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

--[[
XmlNode.__tostring = function(o) 
    sb = StringBuilder()
    o:dump(sb)
    return sb:toString(true)
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
