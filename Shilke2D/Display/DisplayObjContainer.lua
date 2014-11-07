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

--basic math function calls
local min = math.min
local max = math.max
local MAX_VALUE = math.huge
local MIN_VALUE = -math.huge


DisplayObjContainer = class(DisplayObj)

--[[---
DisplayObjContainers must notify all interested children into color changes so to be able 
to correctly react to the events. Used mainly by children objects drawn using pixel shader 
(like quads)
Disabling multiplyColor calling useMultiplyColor() makes possible to optimize DisplayObjContainer 
color / alpha management, but only if sure that no children are using multiplyColor feature
--]]
DisplayObjContainer.__defaultUseMultiplyColor = true

--[[---iterator for DisplayObjContainer children. 
It's possible to retrieve only children of a given 'typeFilter' type
@param displayObjContainer the container of which children must be iterated
@param typeFilter filter on the type of the children
@return next iterator
--]]
function children(displayObjContainer,typeFilter)
	local i = 0
	local n = #displayObjContainer._displayObjs
	if typeFilter then
		return function ()
			local child
			while i <= n-1 do
				i = i + 1
				child = displayObjContainer._displayObjs[i]
				if child:is_a(typeFilter) then 
					return child
				end
			end
		end
	else
		return function ()
			i = i + 1
			if i <= n then 
				return displayObjContainer._displayObjs[i]
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
	local i = #displayObjContainer._displayObjs + 1
	if typeFilter then
		return function ()
			local child
			while i > 1 do
				i = i - 1
				child = displayObjContainer._displayObjs[i]
				if child:is_a(typeFilter) then 
					return child
				end
			end
		end
	else
		return function ()
			i = i - 1
			if i > 0 then 
				return displayObjContainer._displayObjs[i] 
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
	--list of all the displayObjs children of this container
    self._displayObjs = {}
	--list of all the props that will be rendered
    self._objRenderTable = {}
	--it's possible to create a frameBuffer image that will be rendered instead of the 
	--objRenderTable.
	self._frameBufferData = nil
	--The renderTable that will be displayed. _renderTable[2] can be:
	--1)self._objRenderTable: visible container
	--2)a frameBufferImg: visible container drawn using a frameBuffer image
	--3)nil: invisible container
    self._renderTable = {self._prop, self._objRenderTable}
    self._hittable = false
end

--[[---
When an objectContainer is disposed it realease all his children. 
All the children are themself disposed
--]]
function DisplayObjContainer:dispose()
	self:removeChildren(nil,nil,true)
	if self._frameBufferData then
		self:destroyFrameBufferImage()
	end
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
Inner method.
Used to remove a children by the container without setting the new father.
It's used either from removeChild than from addChild for object already added 
to another container
@param obj the obj to remove
@return obj if removed or nil
--]]
function DisplayObjContainer:_innerRemoveChild(obj)
    local pos = table.find(self._displayObjs, obj)
    if pos then
        table.remove(self._displayObjs, pos)
        table.remove(self._objRenderTable, pos)
		return obj
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
    local parent = obj._parent
    if parent then
        parent:_innerRemoveChild(obj)
    end
    self._displayObjs[#self._displayObjs+1] = obj
	self._objRenderTable[#self._objRenderTable+1] = obj._renderTable
    obj:_setParent(self)
	
	--specific logic to handle frameBufferImg instead of normal rendering
	if self._frameBufferData then
		obj._prop:cleatAttrLink(MOAITransform.INHERIT_TRANSFORM)
		obj._prop:cleatAttrLink(MOAIColor.INHERIT_COLOR)
		obj._prop:forceUpdate()
	end
end

--[[---
Remove an obj from children list.
if the object is not a child do nothing
@param obj the obj to be removed
@param dispose if to dispose after removal
@return the obj if removed, nil if the obj is not a child
--]]
function DisplayObjContainer:removeChild(obj,dispose)
	local res = self:_innerRemoveChild(obj)
	if res then
        res:_setParent(nil)
		if dispose == true then
			res:dispose()
		end
	end
	return res
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
        obj.parent:_innerRemoveChild(obj)
    end
    table.insert(self._displayObjs,index,obj)
	table.insert(self._objRenderTable, index, obj._renderTable)
    obj:_setParent(self)
	
	--specific logic to handle frameBufferImg instead of normal rendering
	if self._frameBufferData then
		obj._prop:cleatAttrLink(MOAITransform.INHERIT_TRANSFORM)
		obj._prop:cleatAttrLink(MOAIColor.INHERIT_COLOR)
		obj._prop:forceUpdate()
	end
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
    
    --assert(index1>0 and index2>0)
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
    
    --assert(obj1 and obj2)
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
	DisplayObj.setAlpha(self,a)
	if self._useMultiplyColor then
		self:_updateChildrenColor()
	end
end

function DisplayObjContainer:setColor(r,g,b,a)
	DisplayObj.setColor(self,r,g,b,a)
	if self._useMultiplyColor then
		self:_updateChildrenColor()
	end
end

--[[---
Inner method. Called by parent container, setMultiplyAlpha set the alpha value of the parent container (already
modified by his current multiplyalpha value)
@param r [0,1]
@param g [0,1]
@param b [0,1]
@param a [0,1]
--]]
function DisplayObjContainer:_setMultiplyColor(r,g,b,a)
    --DisplayObj._setMultiplyColor(self,c)
	local mc = self._multiplyColor
	mc[1] = r
	mc[2] = g
	mc[3] = b
	mc[4] = a
    self:_updateChildrenColor()
end

---Inner method. Propagate color value to all children, setting "multiplied color" value
--used by object that need it for correct displaying using pixel shaders
function DisplayObjContainer:_updateChildrenColor()
	local r,g,b,a = 1,1,1,1
	
	if self._useMultiplyColor then
		r,g,b,a = self:_getMultipliedColor() 
	end
	
    for _,o in pairs(self._displayObjs) do
		if o._useMultiplyColor then
			o:_setMultiplyColor(r,g,b,a)
		end
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
			if self._frameBufferData then
				self._renderTable[2] = self._frameBufferData.frameBufferImg._prop
			else
				self._renderTable[2] = self._objRenderTable
			end
		elseif not visible and self._renderTable[2] then
			self._renderTable[2] = nil
		end
	end
end

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


local __helperRect = Rect()

--[[---
The method led to create an image that will be rendered in place of the whole 
displaylist owned by the container.

That can be used for different purposes:

1) to optimize the rendering of a displayList composed of only static objects.
If bUpdate is false or nil in fact, all the children attached to the container are 
rendered once to an image then used as unique displayObj. That can lead 
to a performance increase when the container is made of several static objects. 
The draw back is that the rendering is never updated since a new call to createFrameBufferImage 
or since a call to destroyFrameBufferImage. That means that even if a child is removed, 
set invisible or transofrmed the rendering will shows the state of the container at the moment of the 
image creation. It's possible to specify the size of the area that will be draw (things outside
will be clipped out). If no width/height are provided then container width / height are used 
(with a maximum of 2048x2048)

Very important: the draw of the image will happen next frame, so every change done during the same
frame of the call will be applied even if done after the call.

The logic is similar to Starling flatten / unflatten logic and for that a couple of method with
this name are provided as alias.

2) To create a clip area of given width / height.
If bUpdate is true, an image is created but the rendering is updated each frame. 
That lead to a decrease in performance because the normal rendering has to be done and moreover 
a new texture has to be rendered. The good news is that now we're able to clip a container 
like when using scissor but without the limitation of the scissor of being axis aligned.


An important thing about having a container transformed into an image is that it allows to apply shaders 
transformation to the resulting image, and so to a whole display scene.

NB: the frameBufferImage is always built on a rect that has point (0,0) coincindent with the point (0,0) 
of the container.

@param bUpdate defines if the frameBufferImage will be dynamically updated each frame or created once
and no more update (flatten)
@param width width of the frameBufferImage. Default value is the width of the container. Max = 2048
@param height height of the frameBufferImage. Default value is the height of the container. Max = 2048
--]]
function DisplayObjContainer:createFrameBufferImage(bUpdate,width,height)
	--clear previous frameBufferImg if it exists
	if self._frameBufferData then
		self:destroyFrameBufferImage()
	end
	
	local r = (width and height) and nil or self:getRect(__helperRect)
	
	local width = width or r.w + r.x 
	local height = height or r.h + r.y
	
	--remove the parent of the children objs props
	for _,o in ipairs(self._displayObjs) do
		if not bUpdate then
			o._prop:clearAttrLink(MOAIColor.INHERIT_COLOR)
		end
		o._prop:clearAttrLink(MOAITransform.INHERIT_TRANSFORM)
		o._prop:forceUpdate()
	end
	
	
	local renderTexture = RenderTexture(width, height)
	renderTexture:drawRenderTable(self._objRenderTable, bUpdate)
	
	-- Create an image with correct coorindate system to handle onscreen rendering
	local pivotMode = __USE_SIMULATION_COORDS__ == true and PivotMode.BOTTOM_LEFT	or PivotMode.TOP_LEFT 
	local frameBufferImg = Image(renderTexture, pivotMode)
	
	-- bind this new image (just as prop) to the current layer
	if not bUpdate then
		frameBufferImg._prop:setAttrLink(MOAIColor.INHERIT_COLOR, self._prop, MOAIColor.COLOR_TRAIT)	
	end
	frameBufferImg._prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self._prop, MOAITransform.TRANSFORM_TRAIT)	
	frameBufferImg._prop:forceUpdate()
	
	-- replace the img to the renderTable
	if self._renderTable[2] then
		self._renderTable[2] = frameBufferImg._prop
	end
	
	self._frameBufferData = {
		frameBufferImg = frameBufferImg,
		isFlattened = not bUpdate
	}
end

--[[---
Removes the frameBufferImage previously created with a createFrameBufferImage call and restores
normal draw of the container.
--]]
function DisplayObjContainer:destroyFrameBufferImage()
	if self._frameBufferData then
		--first reset renderTable status if visible
		if self._renderTable[2] then
			self._renderTable[2] = self._objRenderTable
		end
	
		local bFlattened = self._frameBufferData.isFlattened
		
		for _,o in ipairs(self._displayObjs) do
			if bFlattened then
				o._prop:setAttrLink(MOAIColor.INHERIT_COLOR, self._prop, MOAIColor.COLOR_TRAIT)
			end
			o._prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, self._prop, MOAITransform.TRANSFORM_TRAIT)
			o._prop:forceUpdate()
		end
		
		local frameBufferImg 	= self._frameBufferData.frameBufferImg
		local frameBufferTxt 	= frameBufferImg.texture
	
		frameBufferImg:dispose()
		frameBufferTxt:dispose()
		
		self._frameBufferData = nil
	end
end

---Returns the frameBufferImage previously created with a createFrameBufferImage call
--@return framBufferImage or nil
function DisplayObjContainer:getFrameBufferImage()
	return self._frameBufferData and self._frameBufferData.frameBufferImg or nil
end

---alias for createFrameBufferImage call with bUpdate = false
--Takes the name from original Starling sprite:flatten logic
--@param w width of the flattened area (that always begin in 0,0)
--@param h height of the flattened area (that always begin in 0,0)
function DisplayObjContainer:flatten(w,h)
	self:createFrameBufferImage(false,w,h)
end

---alias for destroyFrameBufferImage call
--Takes the name from original Starling sprite:unflatten logic
function DisplayObjContainer:unflatten()
	self:destroyFrameBufferImage()
end

---Check if a frameBufferData is present with isFlattened = true
--@return bool
function DisplayObjContainer:isFlattened()
	return self._frameBufferData and self._frameBufferData.isFlattened or false
end


---alias for createFrameBufferImage call with dynamic update set to true
--@param w width of the clip area (that always begin in 0,0)
--@param h height of the clip area (that always begin in 0,0)
function DisplayObjContainer:setClipArea(w,h)
	self:createFrameBufferImage(true,w,h)
end

---alias for destroyFrameBufferImage call
--Takes the name from original Starling sprite:unflatten logic
function DisplayObjContainer:destroyClipArea()
	self:destroyFrameBufferImage()
end

---Check if a frameBufferData is present with isFlattened = false (so dynamic)
--@return bool
function DisplayObjContainer:hasClipArea()
	return self._frameBufferData and not self._frameBufferData.isFlattened or false
end
