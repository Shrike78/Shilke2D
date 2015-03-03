--[[---
The DisplayObject derives from EventDispatcher and is the base class for all 
objects that are rendered on the screen.

- The Display Tree

All displayable objects are organized in a display tree.
Only objects that are part of the display tree will be displayed (rendered). 
The display tree consists of leaf nodes that will be rendered directly to the 
screen, and of container nodes (instances or subclasses of 
	"DisplayObjectContainer"). 

A container is simply a display object that has child nodes, which can, again, 
be either leaf nodes or other containers.

A display object has properties that define its position in relation 
to its parent (x, y), as well as its rotation and scaling factors 
(scaleX, scaleY). Use the alpha and visible properties to make an 
object translucent or invisible.

- Transforming coordinates

Within the display tree, each object has its own local coordinate 
system. If you rotate a container, you rotate that coordinate system
and thus all the children of the container.

Depending on __USE_DEGREES_FOR_ROTATIONS__ value, rotation is expressed 
in radians or degrees (default is radians)

- Color, Alpha and BlendModes

By default displayobject are configured to use premultiplied alpha instead of straight alpha.

That can be changed using 

DisplayObj:setPremultipliedAlpha()

Choosing between premultiplied or straight alpha setting changes how blendmodes apply 
to objects. Premultiplied alpha it's usually the best choice because it saves calculation 
time giving better performances.

It's also possible to change the blend mode of a display object using 

DisplayObj:setBlendMode() 

that accept or a blend equation with a src and dst blend factors, or a blend mode preset.
(see Display.BlendMode module)


- TargetSpace

Several methods returns geometrical infos about the displayObject related to a 
specific target space, that can be the local space, or the space of one of the 
ancestors of the object. The targetSpace is defined using the displayObject 
rapresenting the target space itself.

Some of the methods (getSize, getWidth and getHeight) have as default value the local 
target space, because usually the desired behavior is to get the size of the object
in local coords (but it's nice to have the possibility to calculate the size of the object
in a different target space in a easy way).

All the others methods have as default value the top most container (usually the stage), 
because usually functionality like hitTest, getBounds, localToGlobal, globalToLocal refers 
to a different space, stage in particular

- Subclassing

DisplayObject is an abstract class because it doesn't implement the getRect method, that's
supposed to return the containing rect of the displayObject in local coordinates.

All the geometrical methods rely on this function to evaluate local and global bounds. 

Therefore subclassing of a DisplayObj requires a concrete implementation of

function DisplayObj:getRect(resultRect)

--]]

-- basic math function calls
local DEG = math.deg(1)
local RAD = math.rad(1)
local ABS = math.abs
local PI = math.pi
local PI2 = math.pi * 2
local INV_255 = 1/255

local min = math.min
local max = math.max
local MAX_VALUE = math.huge
local MIN_VALUE = -math.huge


-- helper for getBound / rect calls
local __helperRect = Rect()

DisplayObj = class(EventDispatcher)


--- Used to define the default alpha behaviour of a displayObj type. That influences blend modes.
DisplayObj.__defaultHasPremultipliedAlpha = true

local __identityMatrix = MOAITransform.new()

--- Initialization.
function DisplayObj:init()
    EventDispatcher.init(self)
    	
    self._prop = self:_createProp()
	self._renderTable = self._prop
	
	-- exact clone of transformation prop, used to calculate 
	-- transformMatrix depending on a specific targetSpace
	self._localMatrix = MOAITransform.new()
	self._transformMatrix = self._localMatrix
	
    self._name = nil
    self._parent = nil
    
    self._touchable = true
	
	-- set default values for the class
	self._pma = self.__defaultHasPremultipliedAlpha
	
	if not self._pma then
		self:setBlendMode(BlendMode.NORMAL)
	end
	self._color = {1,1,1,1}
end

---
-- If a derived object needs to clean up resources it must inherits this method, 
-- always remembering to call also parent dispose method
function DisplayObj:dispose()
	self:removeFromParent()
	EventDispatcher.dispose(self)
	self._transformMatrix = nil
	self._localMatrix = nil
	self._prop = nil
end

---
-- Create a MOAI prop that the current DisplayObj is going to wrap.
-- Generic displayObjs create generic MOAIProps. If a specific prop is needed
-- just override this method for specific DisplayObj class.
-- @treturn MOAIProp
function DisplayObj:_createProp()
    return MOAIProp.new()
end

---
-- Debug Infos.
-- Can be used to create a description of the single displayObj or of a whole displayList
-- @param recursive has meaning only if the displayObj is a DisplayObjContainer.
-- @return string
function DisplayObj:dbgInfo(recursive)
    local sb = StringBuilder()
    sb:writeln("name = ", self._name)
    sb:writeln("pivot = ", self:getPivot())
    sb:writeln("position = ", self:getPosition())
    sb:writeln("scale = ", self:getScale())
    sb:writeln("rotation = ", self:getRotation())
    sb:writeln("color = ", self:getColor())
    sb:writeln("visible = ", self:isVisible())
    sb:writeln("touchable = ", self:isTouchable())
	
    return sb:toString(true)
end

---
-- It's possible (but optional) to set a name to a display obj.
-- @tparam string name the name of the object. Can be nil
function DisplayObj:setName(name)
    self._name = name
end

---
-- Get the name of the current obj.
-- @treturn string or nil if a name has not been set
function DisplayObj:getName()
    return self._name
end

---
-- Internal method.
-- Called by a DisplayObjContainer when the DisplayObj is added as child
-- @tparam DisplayObjContainer parent if nil the obj is detached from any parent 
function DisplayObj:_setParent(parent)
    self._parent = parent
    if parent then
		-- if not set before it can raise problems
		self._prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, parent._prop, MOAITransform.TRANSFORM_TRAIT)
		self._prop:setAttrLink(MOAIColor.INHERIT_COLOR, parent._prop, MOAIColor.COLOR_TRAIT)
		-- the Attr visible is not handled because displayObjContainer uses a different logic 
		-- for visibility
		-- self._prop:setAttrLink(MOAIProp.INHERIT_VISIBLE, parent._prop, MOAIProp.ATTR_VISIBLE)
    else
		self._prop:clearAttrLink(MOAITransform.INHERIT_TRANSFORM)
		self._prop:clearAttrLink(MOAIColor.INHERIT_COLOR)
		-- self._prop:clearAttrLink(MOAIProp.INHERIT_VISIBLE)
	end
	-- force update of transform matrix
	self._prop:forceUpdate()
end

---
-- Remove a displayObject from the parent container
function DisplayObj:removeFromParent()
    if self._parent then
        self._parent:removeChild(self)
    end
end

---
-- Return the parent DisplayObjContainer
-- @treturn DisplayObjContainer or nil if not attached to any container
function DisplayObj:getParent()
    return self._parent
end

---
-- Return the top most displayObjContainer in the display tree.
-- For all the displayed object the root is Stage
-- @treturn DisplayObjContainer displayObject container or nil if the object has not parent
function DisplayObj:getRoot()
    local root = self
    while(root._parent) do
        root = root._parent
    end
    return root
end

---
-- If the displayList containing the object is attached to the stage, return the stage, else nil
-- @treturn Stage nil if the obj has not the stage as ancestor
function DisplayObj:getStage()
	local root = self:getRoot()
	if root:is_a(Stage) then
		return root
	end
	return nil
end

---
-- Set visibility status of this object
-- @tparam[opt=true] bool visible set visible or hidden the displayObj
function DisplayObj:setVisible(visible)
	self._prop:setVisible(visible)
end


-- MOAIProp.isVisible is defined since MOAI v1.5
if MOAIVersion.current >= MOAIVersion.v1_5_1 then
	---
	-- Get visibility status of the displayObj
	-- @treturn bool
	function DisplayObj:isVisible()
	   return self._prop:isVisible()
	end
else
	function DisplayObj:isVisible()
	   return self._prop:getAttr(MOAIProp.ATTR_VISIBLE) > 0
	end
end

---
-- Set touchable status of the obj.
-- Objects by default are touchable, this method is mainly use to remove touchable status.
-- If objects or whole part of displayList doesn't need touch event handling is better to remove set 
-- this to false to increase performance. If a container is not touchable all its children are not 
-- tested too
-- @tparam[opt=true] bool touchable enable / disable touchable status
function DisplayObj:setTouchable(touchable)
    self._touchable = (touchable ~= false)
end

---
-- Get touchable status of the object
-- @treturn bool
function DisplayObj:isTouchable()
   return self._touchable
end


---
-- Set the blend mode for the display object. A blend mode can be expressed in terms of
-- blend equation plus src & dst blend factors or as named preset (must be a valid 
-- registerd name)
-- @param blendEquation BlendEquation or preset string
-- @param srcFactor BlendFactor or nil
-- @param dstFactor BlendFactor or nil
function DisplayObj:setBlendMode(blendEquation, srcFactor, dstFactor)
	local blendEquation, srcFactor, dstFactor = blendEquation, srcFactor, dstFactor
	if type(blendEquation) == "string" then
		blendEquation, srcFactor, dstFactor = BlendMode.getParams(blendEquation, self._pma)
	end
	self._prop:setBlendEquation(blendEquation)
	self._prop:setBlendMode(srcFactor, dstFactor)
end

---
-- Defines if alpha value has to be used as straight or premultiplied.
-- When the value change the blendMode is reset to NORMAL preset 
--(whith blend factors depending on alpha mode)
-- @tparam[opt=true] bool enable
function DisplayObj:setPremultipliedAlpha(enable)
	local pma = enable ~= false
	if self._pma ~= pma then 
		self._pma = pma
		self:_updateColor()
		self:setBlendMode(BlendMode.NORMAL)
	end
end

---
-- Returns if alpha is used as straight or premultiplied
-- @treturn bool
function DisplayObj:hasPremultipliedAlpha()
	return self._pma
end


-- Inner function used to update color after changing in color / alpha
-- Need to be called every time color or alpha information change 
-- (including premultiplied/straight setting)
function DisplayObj:_updateColor()
	local r,g,b,a = unpack(self._color)
	if self._pma then
		r,g,b = r*a, g*a, b*a
	end
	self._prop:setColor(r,g,b,a)
end
	
---
-- Set red color channel
-- @tparam int r red [0,255]
function DisplayObj:setRed(r)
	self._color[1] = r * INV_255
	self:_updateColor()
end

---
-- Get red color channel
-- @treturn int red [0,255]
function DisplayObj:getRed()
   return self._color[1] * 255
end

---
-- Set green color channel
-- @tparam int g green [0,255]
function DisplayObj:setGreen(g)
	self._color[2] = g * INV_255
	self:_updateColor()
end

---
-- Gets green color channel
-- @treturn int green [0,255]
function DisplayObj:getGreen()
   return self._color[2] * 255
end

---
-- Set blue color channel
-- @tparam int b blue [0,255]
function DisplayObj:setBlue(b)
	self._color[3] = b * INV_255
	self:_updateColor()
end

---
-- Get blue color channel
-- @treturn int blue [0,255]
function DisplayObj:getBlue()
   return self._color[3] * 255
end

---
-- Set alpha value of the object
-- @tparam int a alpha value [0,255]
function DisplayObj:setAlpha(a)
	self._color[4] = a * INV_255
	self:_updateColor()
end

---
-- Return alpha value of the object
-- @treturn int alpha [0,255]
function DisplayObj:getAlpha()
   return self._color[4] * 255
end

---
-- Set obj color.
-- @param r (0,255) value or Color object or hex string or int32 color
-- @param g (0,255) value or nil
-- @param b (0,255) value or nil
-- @param a[opt=nil] (0,255) value or nil
function DisplayObj:setColor(r,g,b,a)
	local c = self._color
	c[1], c[2], c[3], c[4] = Color._toNormalizedRGBA(r,g,b,a)
	self:_updateColor()
end

---
-- Return the current Color of the object
-- @return Color
function DisplayObj:getColor()
	return Color.fromNormalizedValues(unpack(self._color))
end


---
-- Set pivot of the object.
-- Pivot point is the point to which transformation are applied, so position, scaling, rotation are all calculated
-- keeping pivot point as center. By default pivot point is (0,0), depending on coordinats system
-- @param x pivot x position
-- @param y pivot y position
function DisplayObj:setPivot(x,y)
    self._prop:setPiv(x,y,0)
end

---
-- Return current pivot position
-- @return x
-- @return y
function DisplayObj:getPivot()
    local x,y = self._prop:getPiv()
    return x,y
end

---
-- Set Pivot x position
-- @tparam number x
function DisplayObj:setPivotX(x)
	self._prop:setAttr(MOAITransform.ATTR_X_PIV,x)
end

---
-- Get Pivot x position
-- @return x
function DisplayObj:getPivotX()
   return self._prop:getAttr(MOAITransform.ATTR_X_PIV)
end

---
-- Set Pivot y position
-- @tparam number y
function DisplayObj:setPivotY(y)
	self._prop:setAttr(MOAITransform.ATTR_Y_PIV,y)
end

---
-- Get Pivot y position
-- @return y
function DisplayObj:getPivotY()
   return self._prop:getAttr(MOAITransform.ATTR_Y_PIV)
end

---
-- Set object position
-- @tparam number x
-- @tparam number y
function DisplayObj:setPosition(x,y)
    self._prop:setLoc(x,y,0)
end

---
-- Get object position
-- @treturn number x
-- @treturn number y
function DisplayObj:getPosition()
    local x,y = self._prop:getLoc()
    return x,y
end

---
-- Set x position
-- @tparam number x
function DisplayObj:setPositionX(x)
    self._prop:setAttr(MOAITransform.ATTR_X_LOC,x)
end

---
-- Get x position
-- @treturn number x
function DisplayObj:getPositionX()
    return self._prop:getAttr(MOAITransform.ATTR_X_LOC)
end

---
-- Set y position
-- @tparam number y
function DisplayObj:setPositionY(y)
    self._prop:setAttr(MOAITransform.ATTR_Y_LOC,y)
end

---
-- Get y position
-- @treturn number y
function DisplayObj:getPositionY()
    return self._prop:getAttr(MOAITransform.ATTR_Y_LOC)
end 

---
-- Move the obj by x,y units
-- @tparam number x
-- @tparam number y
function DisplayObj:translate(x,y)
    self._prop:addLoc(x,y,0)
end

-- used to force rotation to be clock wise in both coordinate systems
local __rmult = __USE_SIMULATION_COORDS__ and -1 or 1

if not __USE_DEGREES_FOR_ROTATIONS__ then
	
	---
	-- Set rotation value.
	-- Rotation is always applied clock wise.
	-- @tparam number r radians/degrees
	function DisplayObj:setRotation(r)
		self._prop:setRot(0, 0, DEG * r * __rmult)
	end

	---
	-- Get rotation value
	-- @treturn number r radians/degrees
	function DisplayObj:getRotation()
		local _,_,r = self._prop:getRot()
		return RAD * r * __rmult
	end

	--- 
	-- Rotate the obj of the given value
	-- @tparam number r radians/degrees
	function DisplayObj:rotate(r)
		self._prop:addRot(0,0, DEG * r * __rmult)
	end
	
else
	
	function DisplayObj:setRotation(r)
		self._prop:setRot(0, 0, r *__rmult)
	end

	function DisplayObj:getRotation()
		local _,_,r = self._prop:getRot()
		return r * __rmult
	end
	
	function DisplayObj:rotate(r)
		self._prop:addRot(0, 0, r * __rmult)
	end

end


---
-- Set scale
-- @tparam number x
-- @tparam number y
function DisplayObj:setScale(x,y)
    self._prop:setScl(x,y)
end

---
-- Get scale value
-- @treturn number x
-- @treturn number y
function DisplayObj:getScale()
	local x,y = self._prop:getScl()
	return x,y
end

--- 
-- Scale of factors x,y. if the object was already scaled it applies 
-- the new factors over the previous (resulting in a multiply of old 
-- and new factors)
-- @tparam number x
-- @tparam number y
function DisplayObj:scale(x,y)
	local _x,_y = self._prop:getScl()
	self._prop:setScl(x*_x,y*_y)
end

---
-- Set scale x value
-- @tparam number s
function DisplayObj:setScaleX(s)
    self._prop:setAttr(MOAITransform.ATTR_X_SCL,s)
end

---
-- Get scale x value
-- @treturn number
function DisplayObj:getScaleX()
    return self._prop:getAttr(MOAITransform.ATTR_X_SCL)
end

---
-- Set scale y value
-- @tparam number s
function DisplayObj:setScaleY(s)
    self._prop:setAttr(MOAITransform.ATTR_Y_SCL,s)
end

---
-- Get scale y value
-- @treturn number
function DisplayObj:getScaleY()
    return self._prop:getAttr(MOAITransform.ATTR_Y_SCL)
end


---
-- Set all the transform parameters
-- @tparam number x x position
-- @tparam number y y position
-- @tparam number r rotation
-- @tparam number sx x scale
-- @tparam number sy y scale
function DisplayObj:setTransform(x,y,r,sx,sy)
	self:setPosition(x,y)
	self:setRotation(r)
	self:setScale(sx,sy)
end

---
-- Get all the transform parameters
-- @treturn number x x position
-- @treturn number y y position
-- @treturn number r rotation
-- @treturn number sx x scale
-- @treturn number sy y scale
function DisplayObj:getTransform()
	local x,y = self:getPosition()
	local r = self:getRotation()
	local sx,sy = self:getScale()
	return x,y,r,sx,sy
end


---
-- Inner method, called to force update of transformation matrix used 
-- to calculate relative position into the displayList
-- @param targetSpace could be self, nil or an ancestor displayObj.
-- nil means top most container
function DisplayObj:updateTransformationMatrix(targetSpace)
	
	-- if the target is itself returns identity matrix
	if (targetSpace == self or (not targetSpace and not self._parent)) then
		self._transformMatrix = __identityMatrix
		return
	end
	
	local root = self:getRoot()
	local targetSpace = targetSpace or root
	
	-- if the target is the root, uses _prop matrix component
	if targetSpace == root and root:is_a(Stage) then
		self._transformMatrix = self._prop
		-- the matrix chain get usually updated once per frame.
		-- forceUpdate call assure that all components are correctly updated
		self._transformMatrix:forceUpdate()
		return
	end
	
	-- if the target is displayObjContainer different from root
	-- uses local matrix as copy of _prop matrix component
	if self._parent then
		-- assign local matrix to transformMatrix
		self._transformMatrix = self._localMatrix
		self._transformMatrix:setPiv(self._prop:getPiv())
		self._transformMatrix:setLoc(self._prop:getLoc())
		self._transformMatrix:setScl(self._prop:getScl())
		self._transformMatrix:setRot(self._prop:getRot())
		-- if parent is the targetSpace, skip inheritance 'cause it would 
		-- return an identity matrix
		if targetSpace ~= self._parent then
			-- force the update of the parent transformation matrix
			self._parent:updateTransformationMatrix(targetSpace)
			-- set matrices inheritance
			self._transformMatrix:setAttrLink(MOAITransform.INHERIT_TRANSFORM,
				self._parent._transformMatrix, MOAITransform.TRANSFORM_TRAIT)
		end
		-- force udpate
		self._transformMatrix:forceUpdate()
		return
	end
	
	error("the targetSpace " .. targetSpace .. " is not an ancestor of the current obj")
end
	

---
-- Transforms a point from the local coordinate system to 
-- global coordinates. targetSpace define the destination 
-- space of the transformation. If nil is considerede to be 
-- the top most container (for displayed object the 
-- screenspace / stage)
-- @param x coordinate in local system
-- @param y coordinate in local system
-- @param targetSpace destination space of the trasnformation
-- if nil refers to the top most container
function DisplayObj:localToGlobal(x,y,targetSpace)
    self:updateTransformationMatrix(targetSpace)
    local x,y,_ = self._transformMatrix:modelToWorld(x,y,0)
	return x,y
end

---
-- Transforms a point from the global coordinate system to 
-- local coordinates system. targetSpace define the source 
-- space of the transformation, to where x,y belongs. 
-- If nil is considered to be the the top most container 
--(for displayed object the screenspace / stage)
-- @param x coordinate in global system
-- @param y coordinate in global system
-- @param targetSpace source space of the trasnformation
-- If nil refers to the top most container
function DisplayObj:globalToLocal(x,y,targetSpace)
    self:updateTransformationMatrix(targetSpace)
    local x,y,_ = self._transformMatrix:worldToModel(x,y,0)
	return x,y
end


---
-- Used to set an absolute position related to targetSpace 
-- container coordinates (usually the stage).
-- Usefull for drag and drop features
-- @param x global coordinate
-- @param y global coordinate
-- @param targetSpace the coordinate system to which x,y belongs. 
-- If nil refers to the top most container
function DisplayObj:setGlobalPosition(x,y,targetSpace)
	if self._parent then
		x,y = self._parent:globalToLocal(x,y,targetSpace)
	end
    self._prop:setLoc(x,y,0)
end


---
-- Return global position of the object related to the targetSpace provided
--(usually the stage)
-- @param targetSpace related to which position has to be transformed.
-- If nil refers to the top most container
-- @return x
-- @return y
function DisplayObj:getGlobalPosition(targetSpace)
	return self:localToGlobal(self._prop:getLoc(),targetSpace)
end

---
-- Apply a translation based on targetSpace coordinates(usually the stage)
-- @param dx x translation
-- @param dy y translation
-- @param targetSpace in which translation has to been applied. If nil refers to the top most container
function DisplayObj:globalTranslate(dx,dy,targetSpace)
	local px,py = self._prop:getPiv()
	local x,y = self:localToGlobal(px,py,targetSpace)
	x = x + dx
	y = y + dy
	self:setGlobalPosition(x,y,targetSpace)
end

---
-- Bounding rect in local coordinates of the displayObj.
-- Width, Height, hitTest, Bounds all rely on this method that must be
-- defined for concrete displayObj classes.
-- @param resultRect if provided is filled and returned
-- @return Rect 
function DisplayObj:getRect(resultRect)
	error("method must be overridden")
	return resultRect
end

---
-- Get width of the object as it appears in another target space (width is calculated as
-- width of the axis aligned bounding box of the object in that space)
-- @param targetSpace (optional) the object related to which we want to calculate width. default value is 'self'
-- @return width
function DisplayObj:getWidth(targetSpace)
	local targetSpace = targetSpace or self
	return self:getBounds(targetSpace,__helperRect).w
end

---
-- Get height of the object as it appears in another target space (height is calculated as
-- height of the axis aligned bounding box of the object in that space)
-- @param targetSpace (optional) the object related to which we want to calculate height. default value is 'self'
-- @return height
function DisplayObj:getHeight(targetSpace)
	local targetSpace = targetSpace or self
	return self:getBounds(targetSpace,__helperRect).h
end

---
-- Get width and height of the object as it appears in another target space (calculated as
-- size of the axis aligned bounding box of the object in that space)
-- @param targetSpace (optional) the object related to which we want to calculate height. default value is 'self'
-- @return width
-- @return height
function DisplayObj:getSize(targetSpace)
	local targetSpace = targetSpace or self
	local r = self:getBounds(targetSpace,__helperRect)
	return r.w, r.h
end

---
-- Returns a rectangle that completely encloses the object as it 
-- appears in another coordinate system.
-- @param targetSpace (optional) the object related to which we want to calculate bounds. 
-- default value is the top most container
-- @param resultRect (optional) if provided is filled and returned
-- @return Rect
function DisplayObj:getBounds(targetSpace,resultRect)
    local r = self:getRect(resultRect)
	
    if targetSpace ~= self then
        self:updateTransformationMatrix(targetSpace)
		
        local xmin = MAX_VALUE
        local xmax = MIN_VALUE
        local ymin = MAX_VALUE
        local ymax = MIN_VALUE
        local x,y
		
		local _rect = {	{r.x, r.y },
						{r.x, r.y + r.h },
						{r.x + r.w, r.y + r.h },
						{r.x + r.w, r.y }}
        
        for i = 1,4 do
            x,y,_ = self._transformMatrix:modelToWorld(_rect[i][1],_rect[i][2],0)      
            xmin = min(xmin,x)
            xmax = max(xmax,x)
            ymin = min(ymin,y)
            ymax = max(ymax,y)
        end
        r.x,r.y,r.w,r.h = xmin,ymin,(xmax-xmin),(ymax-ymin)
    end
    return r
end

---
-- Returns an array of vertices describing a quad that rapresents object bounding rect as it appears into 
-- another coordinate system
-- @param targetSpace the object related to which we want to calculate the oriented bounds. 
-- default value refers to the top most container
-- @return array of position [x,y,...] for 4 points plus first point replicated. 
-- The array can be directely used for rendering
function DisplayObj:getOrientedBounds(targetSpace)
	local r = self:getRect(__helperRect)
    local vs = {r.x, r.y, r.x, r.y + r.h, r.x + r.w, r.y + r.h, r.x + r.w, r.y }
	
	if targetSpace ~= self then
		self:updateTransformationMatrix(targetSpace)
		for i = 1,4 do
			vs[(i-1)*2+1], vs[(i-1)*2+2],_ = self._transformMatrix:modelToWorld(vs[(i-1)*2+1], vs[(i-1)*2+2],0)
		end
	end
	vs[#vs+1] = vs[1]
	vs[#vs+1] = vs[2]
	return unpack(vs)
end

---
-- Draw the oriented bounding box. Usefull for debug purpose
function DisplayObj:drawOrientedBounds()
	MOAIDraw.drawLine(self:getOrientedBounds(nil))
end

---
-- Draw the axis aligned bound of the object as appears into top most container / stage coords
function DisplayObj:drawAABounds(drawContainer)
	-- drawContainer is unused -> used only by displayObjContainer
	local r = self:getBounds(nil,__helperRect)
    MOAIDraw.drawRect(r.x,r.y,r.x+r.w,r.y+r.h)
end

---
-- Given a x,y point in targetSpace coordinates it check if it falls inside local bounds.
-- @param x coordinate in targetSpace system
-- @param y coordinate in targetSpace system
-- @param targetSpace the referred coorindate system. If nil the top most container / stage
-- @param forTouch boolean. If true the check is done only for visible and touchable object
-- @return self if the hitTest is positive else nil 
function DisplayObj:hitTest(x,y,targetSpace,forTouch)
    -- skip object if the hit test is for touch purpose and the obj is not visible
	-- or not touchable
	if forTouch and (not self._touchable or not self:isVisible()) then
		return nil
	end

	if targetSpace ~= self then
		x,y = self:globalToLocal(x,y,targetSpace)
	end
	
	local r = self:getRect(__helperRect)
	if r:containsPoint(x,y) then
		return self
	end
	return nil
end

