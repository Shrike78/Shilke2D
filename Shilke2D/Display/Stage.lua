 --[[---
Stage is a particular DisplayObjContainer, root node of the displayList tree.
It's initialized by Shilke2D and only object connected to it are rendered. 
A stage cannot be geometrically transformed or moved, so all the related method 
are override and raise errors if called.
--]]
Stage = class(DisplayObjContainer)

--[[---
Called from Shilke2D, it sets the viewport for the scene, the renderTable and 
initializes the 'debug' drawCallback used to show bounding boxes of objects in 
the displayList 
@param viewport the viewport of the scene
--]]
function Stage:init(viewport)
	DisplayObjContainer.init(self)
    self._prop:setViewport(viewport)
    
    self._debugDeck = MOAIScriptDeck.new ()
    self._debugDeck:setDrawCallback ( function()
			if self._showAABounds then
				self:drawAABounds(false)
			end
			if self._showOrientedBounds then
				self:drawOrientedBounds()
			end
		end
	)

    self._debugProp = MOAIProp.new ()
    self._debugProp:setDeck ( self._debugDeck )
    self._bkgColor = {0,0,0,1}
    self._rt = {self._renderTable}
end

---Stage prop is a MOAILayer, not a generic MOAIProp like all the others displayObjs
function Stage:_createProp()
    return MOAILayer.new()
end

---Debug function. Used to show bounding box while rendering.
--@tparam[opt=true] bool showOrientedBounds
--@tparam[opt=false] bool showAABounds boolean
function Stage:showDebugLines(showOrientedBounds,showAABounds)
	self._showOrientedBounds = showOrientedBounds ~= nil and showOrientedBounds or true
	self._showAABounds = showAABounds ~= nil and showAABounds or false
	
	local showDebug = self._showOrientedBounds or self._showAABounds
	
	if showDebug and not self._rt[2] then
		self._rt[2] = self._debugProp
	end
	if not showDebug and self._rt[2] then
		self._rt[2] = nil
	end
end

--[[---
Inner method.
With moai 1.4 clearColor function has been moved to frameBuffer and removed from GfxDevice.
The call checks which method is available and make the proper moai call.
@tparam number r (0,1)
@tparam number g (0,1)
@tparam number b (0,1)
@tparam number a (0,1)
--]]
local function __setClearColor(r,g,b,a)
	if MOAIGfxDevice.getFrameBuffer then
		MOAIGfxDevice.getFrameBuffer():setClearColor(r,g,b,a)
	else
		MOAIGfxDevice.setClearColor(r,g,b,a)
	end
end


--[[---
Set background color.
@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
--]]
function Stage:setBackgroundColor(r,g,b,a)
	local r,g,b,a = Color._toNormalizedRGBA(r,g,b,a)
	self._bkgColor = {r,g,b,a}
	__setClearColor(r,g,b,a)
end

--[[---
Get background color.
@treturn Color
--]]
function Stage:getBackgroundColor()
	return Color.fromNormalizedValues(unpack(self._bkgColor))
end


---Raise error if called because stage cannot be added as child to other containers
function Stage:_setParent(parent)
    error("Stage cannot be child of another DisplayObjContainer")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPivot(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPivotX(x)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPivotY(y)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPosition(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPosition_v2(v)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPositionX(x)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setPositionY(y)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:translate(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setRotation(r)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setScale(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setScale_v2(v)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setScaleX(s)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setScaleY(s)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:setGlobalPosition(x,y,targetSpace)
    error("It's not possible to set geometric properties of a Stage")
end

---Raise error if called because stage cannot be geometrically trasnformed
function Stage:globalTranslate(dx,dy,targetSpace)	
    error("It's not possible to set geometric properties of a Stage")
end
