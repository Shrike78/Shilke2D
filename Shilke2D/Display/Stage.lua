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
    self._bkgColor = Color(0,0,0,1)
    self._rt = {self._renderTable}
end

---Stage prop is a MOAILayer, not a generic MOAIProp like all the others displayObjs
function Stage:_createProp()
    return MOAILayer.new()
end

function Stage:clone()
	error("it's not possible to clone a stage")
	return nil
end

function Stage:copy(src)
	error("it's not possible to copy a stage")
	return false
end

---Debug function. Used to show bounding box while rendering.
--@param showOrientedBounds boolean. if nil is set to true
--@param showAABounds boolean. if nil is set to false
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
@param r red component [0..1]
@param g green component [0..1]
@param b blue component [0..1]
@param a alpha component [0..1]
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
@param r red component [0..255] or Color
@param g green component [0..255] or nil
@param b blue component [0..255] or nil
--]]
function Stage:setBackground(r,g,b)
	if class_type(r) == Color then
		__setClearColor(r:unpack_normalized())
		self._bkgColor.r = r.r
		self._bkgColor.g = r.g
		self._bkgColor.b = r.b
	else
		__setClearColor(r/255,g/255,b/255,1)
		self._bkgColor.r = r
		self._bkgColor.g = g
		self._bkgColor.b = b
	end
end

--[[---
Set background color.
@param r red component [0..255] or Color
@param g green component [0..255] or nil
@param b blue component [0..255] or nil
--]]
function Stage:getBackground()
	return self._bkgColor
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
