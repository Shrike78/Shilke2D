-- DisplayObjContainer

--[[
A DisplayObjectContainer represents a collection of display objects.
It is the base class of all display objects that act as a container 
for other objects. By maintaining an ordered list of children, it
defines the back-to-front positioning of the children within the 
display tree.

A container does not a have size in itself. The width and height 
properties represent the extents of its children. 

It can handle 2 type of displayObj: geometrical shapes or anyway objs
that have their own draw logic, and images tha are not handled 
directly, but remapped on quad of meshes shared between images with 
the same texture (or super texture when speaking of texture atlas)

- Adding and removing children

The class defines methods that allow you to add or remove children.

When you add a child, it will be added at the frontmost position, 
possibly occluding a child that was added before.

That is not always true for images/mesh quads: to optimize mesh usage
all the quads are managed by a pool so, once an image is removed
from the container, the relative quad is collapsed and stored in the 
pool, and used again for the next image added to the container (with 
the same texture). In that way an Image added last can be draw before 
image added previously. The only way to guarantee mesh draw order is 
to avoid remove operations
--]]

DisplayObjContainer = class(DisplayObj)

--iterator for DisplayObjContainer children. It's possible to retrieve only children of 
--a given 'typeFilter' type
function children(displayObjContainer,typeFilter)
	local i = 0
	local n = displayObjContainer:getNumChildren()
	if typeFilter then
		return function ()
			while i <= n-1 do
				i = i + 1
				local child = displayObjContainer:getChildAt(i)
				if child:is_a(typeFilter) then 
					return child
				end
			end
		end
	else
		return function ()
			i = i + 1
			if i <= n then 
				return displayObjContainer:getChildAt(i) 
			end
		end
	end
end
	
--reverse iterator for DisplayObjContainer children. It's possible to retrieve only children of 
--a given 'typeFilter' type
function reverse_children(displayObjContainer,typeFilter)
	local i = displayObjContainer:getNumChildren() + 1
	if typeFilter then
		return function ()
			while i > 1 do
				i = i - 1
				local child = displayObjContainer:getChildAt(i) 
				if child:is_a(typeFilter) then 
					return child
				end
			end
		end
	else
		return function ()
			i = i - 1
			if i > 0 then 
				return displayObjContainer:getChildAt(i) 
			end
		end
	end
end

function DisplayObjContainer:init()
    DisplayObj.init(self)
    self._displayObjs = {}
    self._objRenderTable = {}
    self._renderTable = {self._prop, self._objRenderTable}
    self._hittable = false
end

function DisplayObjContainer:dispose()
	self:removeChildren(nil,nil,true)
	DisplayObj.dispose(self)
end

-- Debug Infos and __tostring redefinition
function DisplayObjContainer:dbgInfo(recursive)
    local sb = StringBuilder()
    sb:write(DisplayObj.dbgInfo(self,recursive))
    if recursive then 
        for _,o in ipairs(self._displayObjs) do
            sb:writeln(o:dbgInfo(true))
        end
    end
    return sb:toString(true)
end

--Do not display itself if it's a container
--TODO: verify a possible logic to draw also containers
function DisplayObjContainer:drawOrientedBounds()
    for _,o in ipairs(self._displayObjs) do
        o:drawOrientedBounds(drawContainer)
    end
end

function DisplayObjContainer:drawAABounds(drawContainer)
    if drawContainer then
        DisplayObj.drawAABounds(self,false)
    end
    for _,o in ipairs(self._displayObjs) do
        o:drawAABounds(drawContainer)
    end
end

--returns the first child with a given name, or nil
function DisplayObjContainer:getChildByName(name)
    for _,o in pairs(self._displayObjs) do
        if o._name == name then
            return o
        end
    end
    return nil
end

function DisplayObjContainer:addChild(obj)
	local parent = obj:getParent()
    if parent then
        parent:removeChild(obj)
    end
    table.insert(self._displayObjs,obj)
    if obj:is_a(DisplayObjContainer) then
        table.insert(self._objRenderTable, obj._renderTable)
    else
        table.insert(self._objRenderTable, obj._prop)
    end
    obj:_setParent(self)
end

function DisplayObjContainer:removeChild(obj,dispose)
    local pos = table.find(self._displayObjs, obj)
    if pos then
        table.remove(self._displayObjs, pos)
        table.remove(self._objRenderTable, pos)
        obj:_setParent(nil)
		if dispose == true then
			obj:dispose()
		end
		return obj
    end
	return nil
end

function DisplayObjContainer:getNumChildren()
	return #self._displayObjs
end

function DisplayObjContainer:addChildAt(obj,index)
    if(obj.parent) then
        obj.parent:removeChild(obj)
    end
    table.insert(self._displayObjs,index,obj)
    if obj:is_a(DisplayObjContainer) then
        table.insert(self._objRenderTable, index, obj._renderTable)
    else
        table.insert(self._objRenderTable, index, obj._prop)
    end
    obj:_setParent(self)
end

function DisplayObjContainer:removeChildAt(index,dispose)
    local obj = self._displayObjs[index]
    if obj then
        table.remove(self._displayObjs,index)
        table.remove(self._objRenderTable,index)
        obj:_setParent(nil)
		if dispose == true then
			obj:dispose()
		end
    end
	return obj
end

function DisplayObjContainer:removeChildren(beginIndex, endIndex, dispose)
	local beginIndex = beginIndex or 1
	local endIndex = endIndex or #self._displayObjs
	
	if (endIndex < 0 or endIndex >= #self._displayObjs) then
		endIndex = #self._displayObjs
	end
	
	for i = beginIndex, endIndex do
		self:removeChildAt(beginIndex,dispose)
	end
end
		
--returns the index of a given displayObj, if contained, or 0 if not. 
function DisplayObjContainer:getChildIndex(obj)
    return table.find(self._displayObjs,obj)
end

--returns the displayObj at the given index. 
function DisplayObjContainer:getChildAt(index)
    return self._displayObjs[index]
end

--Swap two given children in the displayList. doesn't work with
--quads and derived classes
function DisplayObjContainer:swapChildren(obj1,obj2)
    local index1 = table.find(self._displayObjs,obj1)
    local index2 = table.find(self._displayObjs,obj2)
    
    assert(index1>0 and index2>0)
  
    self._displayObjs[index1] = obj2
    self._displayObjs[index2] = obj1
    
    local tmp = self._objRenderTable[index1]
    
    self._objRenderTable[index1] = self._objRenderTable[index2]
    self._objRenderTable[index2] = tmp
end

--Swap the two children at the given positions in the displayList 
function DisplayObjContainer:swapChildrenAt(index1,index2)
    local obj1 = self._displayObjs[index1]
    local obj2 = self._displayObjs[index2]
    
    assert(obj1 and obj2)
    
    self._displayObjs[index1] = obj2
    self._displayObjs[index2] = obj1

    local tmp = self._objRenderTable[index1]
    
    self._objRenderTable[index1] = self._objRenderTable[index2]
    self._objRenderTable[index2] = tmp
end

function DisplayObjContainer:setAlpha(a)
    --DisplayObj.setAlpha(self,a)
    self._alpha = a
    self:_updateChildrenAlpha()
end

function DisplayObjContainer:_setMultiplyAlpha(a)
    --DisplayObj.setMultiplyAlpha(self,a)
    self._multiplyAlpha = a / 255
    self:_updateChildrenAlpha()
end

--propagate alpha to all children
function DisplayObjContainer:_updateChildrenAlpha()
    local a = self._alpha * self._multiplyAlpha
    
    for _,o in pairs(self._displayObjs) do
        o:_setMultiplyAlpha(a)
    end
end


--By default the hitTet over a DisplayObjContainer is an hitTest over
--all its children. It's possible anyway to set itself as target of
--an hitTest, without going deep in the displayList
function DisplayObjContainer:setHittable(hittable)
    self._hittable = hittable
end

function DisplayObjContainer:isHittable()
    return self._hittable
end

function DisplayObjContainer:setVisible(visible)
	if self._visible ~= visible then
		DisplayObj.setVisible(self,visible)
		
		if visible and not self._renderTable[2] then
			self._renderTable[2] = self._objRenderTable
		elseif not visible and self._renderTable[2] then
			self._renderTable[2] = nil
		end
	end
end

local min = math.min
local max = math.max
local MAX_VALUE = math.huge
local MIN_VALUE = -math.huge

function DisplayObjContainer:getRect(resultRect)
	local r = resultRect or Rect()
	if #self._displayObjs == 0 then
        r.x,r.y,r.w,r.h = 0,0,0,0
    else
        local xmin = MAX_VALUE
        local xmax = MIN_VALUE
        local ymin = MAX_VALUE
        local ymax = MIN_VALUE
		for _,obj in ipairs(self._displayObjs) do
			r = obj:getBounds(self,r)
			xmin = min(xmin,r.x)
			xmax = max(xmax,r.x+r.w)
			ymin = min(ymin,r.y)
			ymax = max(ymax,r.y+r.h)
		end
		--On MOAI layer are placed by MOAITransform logic, so 0,0 is always the same point
		xmin = min(xmin,0)
		xmax = max(xmax,0)
		ymin = min(ymin,0)
		ymax = max(ymax,0)
		
        r.x,r.y,r.w,r.h = xmin,ymin,(xmax-xmin),(ymax-ymin)
    end
    return r
end

--[[
If the container is set as hittable, the hitTest will be done only
on its own boundary without hittesting all the children, and the 
resulting target will be itself. If not hittable instead, the hitTest
will bendone on children, ustarting from then topmost 
displayObjContainer.
--]]
function DisplayObjContainer:hitTest(x,y,targetSpace,forTouch)
    if self._hittable then
        return DisplayObj.hitTest(self,x,y,targetSpace,forTouch)   
    elseif not forTouch or (self:isVisible() and self._touchable) then
        local _x,_y
        if targetSpace == self then
            _x,_y = x,y
        else
            _x,_y = self:globalToLocal(x,y,targetSpace)
        end
        local target = nil
		for i = #self._displayObjs,1,-1 do
			target = self._displayObjs[i]:hitTest(_x,_y,self,forTouch)
			if target then 
				return target
			end
		end
    end
    return nil
end
