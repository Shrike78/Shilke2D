--[[---
A DisplayObjectContainer represents a collection of display objects.
It is the base class of all display objects that act as a container 
for other objects. By maintaining an ordered list of children, it
defines the back-to-front positioning of the children within the 
display tree.

A container does not a have size in itself. The width and height 
properties represent the extents of its children. 

- Adding and removing children

The class defines methods that allow you to add or remove children.

When you add a child, it will be added at the frontmost position, 
possibly occluding a child that was added before.
--]]

DisplayObjContainer = class(DisplayObj)

--[[---iterator for DisplayObjContainer children. 
It's possible to retrieve only children of a given 'typeFilter' type
@param displayObjContainer the container of which children must be iterated
@param typeFilter filter on the type of the children
@return next iterator
--]]
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
	
--[[---
Reverse iterator for DisplayObjContainer children. 
It's possible to retrieve only children of a given 'typeFilter' type
@param displayObjContainer the container of which children must be iterated
@param typeFilter filter on the type of the children
@return next (reverse) iterator
--]]
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

--[[---
Initialization method.
Children displayObj list is built as well as objRenderTalbe list.
--]]
function DisplayObjContainer:init()
    DisplayObj.init(self)
    self._displayObjs = {}
    self._objRenderTable = {}
    self._renderTable = {self._prop, self._objRenderTable}
    self._hittable = false
end

--[[---
When an objectContainer is disposed it realease all his children. 
All the children are themself disposed
--]]
function DisplayObjContainer:dispose()
	self:removeChildren(nil,nil,true)
	DisplayObj.dispose(self)
end

---Debug Infos
--@param recursive boolean, if true dbgInfo will be called also for all the children
--@return string
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

---Draws oriented bounds for all his children
function DisplayObjContainer:drawOrientedBounds()
    for _,o in ipairs(self._displayObjs) do
        o:drawOrientedBounds(drawContainer)
    end
end

---Draws axis aligned bounds for all his children.
--@param drawContainer boolean, if true also container bounds will be drawn
function DisplayObjContainer:drawAABounds(drawContainer)
    if drawContainer then
        DisplayObj.drawAABounds(self,false)
    end
    for _,o in ipairs(self._displayObjs) do
        o:drawAABounds(drawContainer)
    end
end

---Returns the first child with a given name, if it exists, or nil
--@param name of the child to be searched
--@return displayObj or nil
function DisplayObjContainer:getChildByName(name)
    for _,o in pairs(self._displayObjs) do
        if o._name == name then
            return o
        end
    end
    return nil
end

--[[---
Add a displayObj to the children list.
The child is add at the end of the children list so it's the top most of the drawn children.
If the obj already has a parent, first is removed from the parent and then added to the new 
parent container.
@param obj the obj to be added as child
--]]
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

--[[---
Remove an obj from children list.
if the object is not a child do nothing
@param obj the obj to be removed
@param dispose if to dispose after removal
@return the obj if removed, nil if the obj is not a child
--]]
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

---Return the number of children
--@return size of displayObj list
function DisplayObjContainer:getNumChildren()
	return #self._displayObjs
end

---Add a child at given position 
--@param obj the obj o be added
--@param index the desired position
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

---Remove a child at a given position
--@param index the position of the obj to be removed
--@param dispose boolean, if to dispose the obj after removal
--@return the obj if the index is valid or nil
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

---Remove all the children between two indices
--@param beginIndex index of the first object to be removed
--@param endIndex index of the last object to be removed
--@param dispose if to dispose the objects after removal
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
		
---Returns the index of a given displayObj, if contained, or 0 if not. 
--@param obj the obj to be searched
--@return obj position in children list or 0 if obj is not a child 
function DisplayObjContainer:getChildIndex(obj)
    return table.find(self._displayObjs,obj)
end

---Returns the displayObj at the given index. 
--@param index the index of the obj to be returned
--@return the obj at position 'index' or nil if it doesn't exist
function DisplayObjContainer:getChildAt(index)
    return self._displayObjs[index]
end

---Swap two given children in the displayList.
--If both the object are children, swap the positions
--@param obj1 first object to be moved
--@param obj2 second object to be moved
function DisplayObjContainer:swapChildren(obj1,obj2)
    local index1 = table.find(self._displayObjs,obj1)
    local index2 = table.find(self._displayObjs,obj2)
    
    assert(index1>0 and index2>0)
	if (index1>0 and index2>0) then
		self._displayObjs[index1] = obj2
		self._displayObjs[index2] = obj1

		local tmp = self._objRenderTable[index1]
		
		self._objRenderTable[index1] = self._objRenderTable[index2]
		self._objRenderTable[index2] = tmp
	end
end

---Swap two children at given positions in the displayList
--If both the indices are valid, swap the relative objects
--@param index1 index of the first object to be moved
--@param index2 index of the second object to be moved
function DisplayObjContainer:swapChildrenAt(index1,index2)
    local obj1 = self._displayObjs[index1]
    local obj2 = self._displayObjs[index2]
    
    assert(obj1 and obj2)
    if obj1 and obj2 then
		self._displayObjs[index1] = obj2
		self._displayObjs[index2] = obj1

		local tmp = self._objRenderTable[index1]
		
		self._objRenderTable[index1] = self._objRenderTable[index2]
		self._objRenderTable[index2] = tmp
	end
end

---Set container alpha value
--@param a [0,255]
function DisplayObjContainer:setAlpha(a)
    self._alpha = math.clamp(a,0,255)
    self:_updateChildrenAlpha()
end

--[[---
Inner method. Called by parent container, setMultiplyAlpha set the alpha value of the parent container (already
modified by his current multiplyalpha value)
@param a alpha value [0,255]
--]]
function DisplayObjContainer:_setMultiplyAlpha(a)
    --DisplayObj.setMultiplyAlpha(self,a)
    self._multiplyAlpha = a / 255
    self:_updateChildrenAlpha()
end

---Inner method. Propagate alpha value to all children, setting "multiplied alpha" value
function DisplayObjContainer:_updateChildrenAlpha()
    local a = self._alpha * self._multiplyAlpha
    
    for _,o in pairs(self._displayObjs) do
        o:_setMultiplyAlpha(a)
    end
end


--[[---
By default the hitTet over a DisplayObjContainer is an hitTest over
all its children. It's possible anyway to set itself as target of
an hitTest, without going deep in the displayList
--@param hittable boolean
--]]
function DisplayObjContainer:setHittable(hittable)
    self._hittable = hittable
end

---Returns if a DisplayObjContainer can be direct target of a touch event
--@return boolean
function DisplayObjContainer:isHittable()
    return self._hittable
end

---Change visibility status of the container
--@param visible boolean
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

---Return a rect obtained by children rect
--Iterates over all the children and calculates a rectangle that enclose them all.
--@param resultRect it's possibile to pass a Rect helper to store results
--@return a rect filled with bound infos
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

--[[---
Given a x,y point in targetSpace coordinates it check if it falls inside local bounds.
If the container is set as hittable, the hitTest will be done only on its own boundary 
without testing all the children, and the resulting target will be itself. If not 
hittable instead, the hitTest will be done on children, starting from then topmost 
displayObjContainer.

@param x coordinate in targetSpace system
@param y coordinate in targetSpace system
@param targetSpace the referred coorindate system. if nil the top most container / stage
@param forTouch boolean. If true the check is done only for visible and touchable object
@return self if the hitTest is positive else nil 
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
