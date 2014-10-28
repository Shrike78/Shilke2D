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

--basic math function calls
local DEG = math.deg
local RAD = math.rad
local ABS = math.abs
local PI = math.pi
local PI2 = math.pi * 2
local INV_255 = 1/255

local min = math.min
local max = math.max
local MAX_VALUE = math.huge
local MIN_VALUE = -math.huge


--helper for getBound / rect calls
local __helperRect = Rect()

DisplayObj = class(EventDispatcher)

--[[---
By default DisplayObjs do not make use of multiplyColor because the
resulting color on screen is automatically affected by hierarchy colors.
Special cases are when an object is rendered using a shader that doesn't
take care of hierarchy, and so it's required to manually modify colors 
according to multiply value.
--]]
DisplayObj.__defaultUseMultiplyColor = false

---Used to define the default alpha behaviour of a displayObj type. That influences blend modes.
DisplayObj.__defaultHasPremultipliedAlpha = true

---Initialization.
function DisplayObj:init()
    EventDispatcher.init(self)
    	
    self._prop = self:_createProp()
	self._renderTable = self._prop
	
	--exact clone of transformation prop, used to calculate transformMatrix depending
	--on a specific targetSpace
	self._transformMatrix = MOAITransform.new()
	
    self._name = nil
    self._parent = nil
    
	self._visible = true
    self._touchable = true
	
	--set default values for the class
	self._useMultiplyColor = self.__defaultUseMultiplyColor
	self._premultipliedAlpha = self.__defaultHasPremultipliedAlpha
	
	self._blendEquation = BlendEquation.GL_FUNC_ADD
	self._blendSrcFactor = BlendFactor.GL_ONE
	self._blendDstFactor = BlendFactor.GL_ONE_MINUS_SRC_ALPHA
	if not self._premultipliedAlpha then
		self:setBlendMode(BlendMode.NORMAL)
	end
	self._color = {1,1,1,1}
    self._multiplyColor = {1,1,1,1}

end

---If a derived object needs to clean up resources it must inherits this method, always remembering to 
--call also parent dispose method
function DisplayObj:dispose()
	if self._parent then
		self._parent:removeChild(self)
	end
	EventDispatcher.dispose(self)
	self._transformMatrix = nil
	self._prop = nil
end

---create a MOAI prop that the current DisplayObj is going to wrap.
--Generic displayObjs create generic MOAIProps. If a specific prop is needed
--just override this method for specific DisplayObj class. 
function DisplayObj:_createProp()
    return MOAIProp.new()
end

---Debug Infos.
--Can be used to create a description of the single displayObj or of a whole displayList
--@param recursive has meaning only if the displayObj is a DisplayObjContainer.
--@return string
function DisplayObj:dbgInfo(recursive)
    local sb = StringBuilder()
    sb:writeln("name = ",self._name)
    sb:writeln("pivot = ",self._prop:getPiv())
    sb:writeln("position = ",self._prop:getLoc())
    sb:writeln("scale = ",self._prop:getScl())
    sb:writeln("rotation = ",self._prop:getRot())
    sb:writeln("color = ",self._prop:getColor())
    sb:writeln("visible = ",(self._visible))
    sb:writeln("touchable = ",self._touchable)
	
    return sb:toString(true)
end

---It's possible (but optional) to set a name to a display obj.
--@param name the name of the object. Can be nil
function DisplayObj:setName(name)
    self._name = name
end

---Get the name of the current obj.
--return name (string) or nil if a name has not been set
function DisplayObj:getName()
    return self._name
end

---Internal method.
--Called by a DisplayObjContainer when the DisplayObj is added as child
function DisplayObj:_setParent(parent)
    --assert(not parent or parent:is_a(DisplayObjContainer))
    
    self._parent = parent
    if parent then
		--if not set before it can raise problems
		self._prop:setAttrLink(MOAITransform.INHERIT_TRANSFORM, parent._prop, MOAITransform.TRANSFORM_TRAIT)
		self._prop:setAttrLink(MOAIColor.INHERIT_COLOR, parent._prop, MOAIColor.COLOR_TRAIT)
       	if self._useMultiplyColor then
			self:_setMultiplyColor(parent:_getMultipliedColor())
		end
    else
		self._prop:clearAttrLink(MOAITransform.INHERIT_TRANSFORM)
		self._prop:clearAttrLink(MOAIColor.INHERIT_COLOR)
       	if self._useMultiplyColor then
			self:_setMultiplyColor(1,1,1,1)
		end
	end
	--force update of transform matrix
	self._prop:forceUpdate()
end

---Return the parent DisplayObjContainer
--return parent displayObjContainer or nil if not attached to any container
function DisplayObj:getParent()
    return self._parent
end

---Remove a displayObject from the parent container
function DisplayObj:removeFromParent()
    if self._parent then
        self._parent:removeChild(self)
    end
end

---Return the top most displayObjContainer in the display tree.
--For all the displayed object the root is Stage
--@return root displayObject container or nil if the object has not parent
function DisplayObj:getRoot()
    local root = self
    while(root._parent) do
        root = root._parent
    end
    return root
end

---If the displayList containing the object is attached to the stage, return the stage, else nil
--@return the stage or nil if the obj has not the stage as ancestor
function DisplayObj:getStage()
    local root = self:getRoot()
    if root:is_a(Stage) then
        return root
    else
        return nil
    end
end

-- Setter and Getter

---Set visibility status of this object
--@tparam[opt=true] bool visible set visible or hidden the displayObj
function DisplayObj:setVisible(visible)
	local visible = not (visible == false)
	if self._visible ~= visible then
		self._visible = visible 
		self._prop:setVisible(visible)
	end
end

---Get visibility status of the displayObj
--@return bool
function DisplayObj:isVisible()
   return self._visible
end
    
--[[---
Set touchable status of the obj.
Objects by default are touchable, this method is mainly use to remove touchable status.
If objects or whole part of displayList doesn't need touch event handling is better to remove set 
this to false to increase performance. If a container is not touchable all its children are not 
tested too
@param touchable boolean value to enable / disable touchable status
--]]
function DisplayObj:setTouchable(touchable)
    self._touchable = touchable
end

---Get touchable status of the object
--@return bool
function DisplayObj:isTouchable()
   return self._touchable
end

--[[---
Used to override default 'useMultiplyColor' class value for a specific instance
Used for example for images when a pixel shader is set for special effects.
@param bUse boolean
--]]
function DisplayObj:useMultiplyColor(bUse)
	self._useMultiplyColor = bUse
	if bUse and self._parent then
		self:_setMultiplyColor(self._parent:_getMultiplyColor())
	else
		self:_setMultiplyColor(1,1,1,1)
	end
end

---Returns if the object is using multiplyColor feature
--@return bool
function DisplayObj:isMultiplyingColor()
	return self._useMultiplyColor
end

--[[---
Inner method.
Called by parent container, setMultiplyColor set the multiply color value of the parent container 
(already modified by his current multiplyColor value)
@param r [0,1]
@param g [0,1]
@param b [0,1]
@param a [0,1]
--]]
function DisplayObj:_setMultiplyColor(r,g,b,a)
	local mc = self._multiplyColor
	mc[1] = r
	mc[2] = g
	mc[3] = b
	mc[4] = a
end

--[[---
Inner method.
Returns the color of the object when displayed. 
This value is obtained multiplying the obj color by the parent multiplyColor value
@return r [0,1]
@return g [0,1]
@return b [0,1]
@return a [0,1]
--]] 
function DisplayObj:_getMultipliedColor()
	local mc = self._multiplyColor
	local prop = self._prop
	local r = mc[1] * prop:getAttr(MOAIColor.ATTR_R_COL)  
	local g = mc[2] * prop:getAttr(MOAIColor.ATTR_G_COL)  
	local b = mc[3] * prop:getAttr(MOAIColor.ATTR_B_COL)  
	local a = mc[4] * prop:getAttr(MOAIColor.ATTR_A_COL)  
    return r,g,b,a
end

--[[---
Set the blend mode for the display object. A blend mode can be expressed in terms of
blend equation plus src & dst blend factors or as named preset (must be a valid 
registerd name)
@param blendEquation BlendEquation or preset string
@param srcFactor BlendFactor or nil
@param dstFactor BlendFactor or nil
--]]
function DisplayObj:setBlendMode(blendEquation, srcFactor, dstFactor)
	if type(blendEquation) == "string" then
		blendEquation, srcFactor, dstFactor = BlendMode.getParams(blendEquation, self._premultipliedAlpha)
	end
	self._blendEquation = blendEquation
	self._blendSrcFactor, self._blendDstFactor = srcFactor, dstFactor
	self._prop:setBlendEquation(self._blendEquation)
	self._prop:setBlendMode(self._blendSrcFactor, self._blendDstFactor)
end

--[[---
return current blend mode in terms of blend equation and blend factors
@return BlendEquation the currently set blend equation
@return BlendFactor the currentrly set src blend factor
@return BlendFactor the currentrly set dst blend factor
--]]
function DisplayObj:getBlendMode()
	return self._blendEquation, self._blendSrcFactor, self._blendDstFactor
end

--[[---
Defines if alpha value has to be used as straight or premultiplied.
When the value change the blendMode is reset to NORMAL preset 
(whith blend factors depending on alpha mode)
@tparam[opt=true] bool bUse
--]]
function DisplayObj:setPremultipliedAlpha(bUse)
	local bPremultipliedAlpha = bUse ~= false
	if self._premultipliedAlpha ~= bPremultipliedAlpha then 
		self._premultipliedAlpha = bPremultipliedAlpha
		self:_updateColor()
		self:setBlendMode(BlendMode.NORMAL)
	end
end

---Returns if alpha is used as straight or premultiplied
--@return bool
function DisplayObj:hasPremultipliedAlpha()
	return self._premultipliedAlpha
end

--[[
Inner function used to update color after changing in color / alpha
Need to be called every time color or alpha information change 
(including premultiplied/straight setting)
--]]
function DisplayObj:_updateColor()
	local c = self._color
	if self._premultipliedAlpha then
		local a = c[4]
		self._prop:setColor(c[1]*a,c[2]*a,c[3]*a,a)
	else
		self._prop:setColor(c[1],c[2],c[3],c[4])
	end
end


---Set alpha value of the object
--@param a alpha value [0,255]
function DisplayObj:setAlpha(a)
	self._color[4] = a * INV_255
	self:_updateColor()
end

--Return alpha value of the object
--@return alpha [0,255]
function DisplayObj:getAlpha()
   return self._color[4] * 255
end


--[[---
Set obj color.
The following calls are valid:
- setColor(r,g,b)
- setColor(r,g,b,a)
- setColor("#FFFFFF")
- setColor("#FFFFFFFF")
- setColor(Color)
@param r red value [0,255] or a Color or hex string
@param g green value [0,255] or nil
@param b blue value [0,255] or nil
@param a alpha value [0,255] or nil
--]]
function DisplayObj:setColor(r,g,b,a)
	local c = self._color
	c[1], c[2], c[3], c[4] = Color._paramConversion(r,g,b,a,c[4])
	self:_updateColor()
end

---Return the current Color of the object
--@return Color
function DisplayObj:getColor()
	return Color.fromNormalizedValues(unpack(self._color))
end


--[[---
Set pivot of the object.
Pivot point is the point to which transformation are applied, so position, scaling, rotation are all calculated
keeping pivot point as center. By default pivot point is (0,0), depending on coordinats system
@param x pivot x position
@param y pivot y position
--]]
function DisplayObj:setPivot(x,y)
    self._prop:setPiv(x,y,0)
end

---Return current pivot position
--@return x
--@return y
function DisplayObj:getPivot()
    local x,y = self._prop:getPiv()
    return x,y
end

---Set pivot of the object using a vec2
--@param v vec2 
function DisplayObj:setPivot_v2(v)
    self._prop:setPiv(v.x,v.y,0)
end

---Return current pivot position using a vec2
--@return vec2
function DisplayObj:getPivot_v2()
    local x,y = self._prop:getPiv()
    return vec2(x,y)
end

---Set Pivot x position
function DisplayObj:setPivotX(x)
	self._prop:setAttr(MOAITransform.ATTR_X_PIV,x)
end

---Get Pivot x position
--@return x
function DisplayObj:getPivotX()
   return self._prop:getAttr(MOAITransform.ATTR_X_PIV)
end

---Set Pivot y position
function DisplayObj:setPivotY(y)
	self._prop:setAttr(MOAITransform.ATTR_Y_PIV,y)
end

---Get Pivot y position
--@return y
function DisplayObj:getPivotY()
   return self._prop:getAttr(MOAITransform.ATTR_Y_PIV)
end

--[[
All the following methods set or get the geometric transformation 
of the object relative to the local coordinates of the parent.
pos and scale have single coords accessors but also coupled (on x 
and y) accessors for performance issues, and "_v2" (vec2) version, 
usefull in different situation (like tweening)
--]]

---Set object position
function DisplayObj:setPosition(x,y)
    self._prop:setLoc(x,y,0)
end

---Get object position
--@return x
--@return y
function DisplayObj:getPosition()
    local x,y = self._prop:getLoc()
    return x,y
end

---Set object position using a vec2
--@param v vec2(x,y)
function DisplayObj:setPosition_v2(v)
    self._prop:setLoc(v.x,v.y,0)
end

---Get object position using a vec2
--@return vec2(x,y)
function DisplayObj:getPosition_v2()
	local x,y = self._prop:getLoc()
    return vec2(x,y)
end

---Set x position
function DisplayObj:setPositionX(x)
    self._prop:setAttr(MOAITransform.ATTR_X_LOC,x)
end

---Get x position
--@return x
function DisplayObj:getPositionX()
    return self._prop:getAttr(MOAITransform.ATTR_X_LOC)
end

---Set y position
function DisplayObj:setPositionY(y)
    self._prop:setAttr(MOAITransform.ATTR_Y_LOC,y)
end

---Get y position
--@return y
function DisplayObj:getPositionY()
    return self._prop:getAttr(MOAITransform.ATTR_Y_LOC)
end 

---Move the obj by x,y units
function DisplayObj:translate(x,y)
    self._prop:addLoc(x,y,0)
end

--[[---
Set rotation value.
Rotation is expressed in radians and is applied clock wise.
@param r radians
--]]
function DisplayObj:setRotation(r)
    --move into range [-180 deg, +180 deg]
    while (r < -PI) do r = r + PI2 end
    while (r >  PI) do r = r - PI2 end
    self._prop:setAttr(MOAITransform.ATTR_Z_ROT,DEG(r))
end

---Get rotation value
--@return r [-math.pi, math.pi]
function DisplayObj:getRotation()   
	return RAD(self._prop:getAttr(MOAITransform.ATTR_Z_ROT))
end

---Set scale
function DisplayObj:setScale(x,y)
    self._prop:setScl(x,y)
end

---Get scale value
--@return x
--@return y
function DisplayObj:getScale()
    local x,y = self._prop:getScl()
    return x,y
end

---Set scale using vec2
--@param v vec2(x,y)
function DisplayObj:setScale_v2(v)
    self._prop:setScl(v.x,v.y)
end

---Get scale using vec2
--@return  v vec2(x,y)
function DisplayObj:getScale_v2()
    local x,y = self._prop:getScl()
    return vec2(x,y)
end

---Set scale x value
function DisplayObj:setScaleX(s)
    self._prop:setAttr(MOAITransform.ATTR_X_SCL,s)
end

---Get scale x value
--@return x
function DisplayObj:getScaleX()
    return self._prop:getAttr(MOAITransform.ATTR_X_SCL)
end

---Set scale y value
function DisplayObj:setScaleY(s)
    self._prop:setAttr(MOAITransform.ATTR_Y_SCL,s)
end

---Get scale y value
--@return y
function DisplayObj:getScaleY()
    return self._prop:getAttr(MOAITransform.ATTR_Y_SCL)
end


--[[---
Inner method, called to force update of transformation matrix used 
to calculate relative position into the displayList
@param targetSpace could be self, nil or an ancestor displayObj.
nil means top most container
--]]
function DisplayObj:updateTransformationMatrix(targetSpace)
	
	if (targetSpace == self or (not self._parent and not targetSpace) ) then
		if self._bTransformMatrixIsIdentity then 
			return
		else
			self._transformMatrix:clearAttrLink(MOAITransform.INHERIT_TRANSFORM)
			self._transformMatrix:setPiv(0,0,0)
			self._transformMatrix:setLoc(0,0,0)
			self._transformMatrix:setScl(1,1)
			self._transformMatrix:setAttr(MOAITransform.ATTR_Z_ROT,0)
			self._transformMatrix:forceUpdate()
			self._bTransformMatrixIsIdentity = true
			return
		end
	end
	
	if self._parent then
		self._parent:updateTransformationMatrix(targetSpace)
		self._transformMatrix:setAttrLink(MOAITransform.INHERIT_TRANSFORM,
			self._parent._transformMatrix, MOAITransform.TRANSFORM_TRAIT)
		self._transformMatrix:setPiv(self._prop:getPiv())
		self._transformMatrix:setLoc(self._prop:getLoc())
		self._transformMatrix:setScl(self._prop:getScl())
		self._transformMatrix:setAttr(MOAITransform.ATTR_Z_ROT,
			self._prop:getAttr(MOAITransform.ATTR_Z_ROT))
		self._transformMatrix:forceUpdate()
		self._bTransformMatrixIsIdentity = false
		return
	end
	
	error("the targetSpace " .. targetSpace .. " is not an ancestor of the current obj")
end

--[[---
Transforms a point from the local coordinate system to 
global coordinates. targetSpace define the destination 
space of the transformation. If nil is considerede to be 
the top most container (for displayed object the 
screenspace / stage)

@param x coordinate in local system
@param y coordinate in local system
@param targetSpace destination space of the trasnformation
if nil refers to the top most container
--]]
function DisplayObj:localToGlobal(x,y,targetSpace)
    self:updateTransformationMatrix(targetSpace)
    local x,y,z = self._transformMatrix:modelToWorld(x,y,0)
	return x,y
end

--[[---
Transforms a point from the global coordinate system to 
local coordinates system. targetSpace define the source 
space of the transformation, to where x,y belongs. 
If nil is considered to be the the top most container 
(for displayed object the screenspace / stage)

@param x coordinate in global system
@param y coordinate in global system
@param targetSpace source space of the trasnformation
If nil refers to the top most container
--]]
function DisplayObj:globalToLocal(x,y,targetSpace)
    self:updateTransformationMatrix(targetSpace)
    local x,y,z = self._transformMatrix:worldToModel(x,y,0)
	return x,y
end


--[[---
Used to set an absolute position related to targetSpace 
container coordinates (usually the stage).
Usefull for drag and drop features

@param x global coordinate
@param y global coordinate
@param targetSpace the coordinate system to which x,y belongs. 
If nil refers to the top most container
--]]
function DisplayObj:setGlobalPosition(x,y,targetSpace)
	local _x,_y
	if self._parent then
		_x,_y = self._parent:globalToLocal(x,y,targetSpace)
	else
		_x,_y = x,y
	end
    self._prop:setLoc(_x,_y,0)
    self._transformMatrix:setLoc(_x,_y,0)
end


--[[---
Return global position of the object related to the targetSpace provided
(usually the stage)

@param targetSpace related to which position has to be transformed.
If nil refers to the top most container
@return x
@return y
--]]
function DisplayObj:getGlobalPosition(targetSpace)
	return self:localToGlobal(self._prop:getLoc(),targetSpace)
end

--[[---
Apply a translation based on targetSpace coordinates(usually the stage)
@param dx x translation
@param dy y translation
@param targetSpace in which translation has to been applied. If nil refers to the top most container
--]]
function DisplayObj:globalTranslate(dx,dy,targetSpace)
	local px,py = self._prop:getPiv()
	local x,y = self:localToGlobal(px,py,targetSpace)
	x = x + dx
	y = y + dy
	self:setGlobalPosition(x,y,targetSpace)
end

--[[---
Bounding rect in local coordinates of the displayObj.
Width, Height, hitTest, Bounds all rely on this method that must be
defined for concrete displayObj classes.
@param resultRect if provided is filled and returned
@return Rect 
--]]
function DisplayObj:getRect(resultRect)
	error("method must be overridden")
	return resultRect
end

--[[---
Get width of the object as it appears in another target space (width is calculated as
width of the axis aligned bounding box of the object in that space)
@param targetSpace (optional) the object related to which we want to calculate width. default value is 'self'
@return width
--]]
function DisplayObj:getWidth(targetSpace)
	local targetSpace = targetSpace or self
	return self:getBounds(targetSpace,__helperRect).w
end

--[[---
Get height of the object as it appears in another target space (height is calculated as
height of the axis aligned bounding box of the object in that space)
@param targetSpace (optional) the object related to which we want to calculate height. default value is 'self'
@return height
--]]
function DisplayObj:getHeight(targetSpace)
	local targetSpace = targetSpace or self
	return self:getBounds(targetSpace,__helperRect).h
end

--[[---
Get width and height of the object as it appears in another target space (calculated as
size of the axis aligned bounding box of the object in that space)
@param targetSpace (optional) the object related to which we want to calculate height. default value is 'self'
@return width
@return height
--]]
function DisplayObj:getSize(targetSpace)
	local targetSpace = targetSpace or self
	local r = self:getBounds(targetSpace,__helperRect)
	return r.w, r.h
end

--[[---
Returns a rectangle that completely encloses the object as it 
appears in another coordinate system.
@param targetSpace (optional) the object related to which we want to calculate bounds. 
default value is the top most container
@param resultRect (optional) if provided is filled and returned
@return Rect
--]]
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
            x,y = self._transformMatrix:modelToWorld(_rect[i][1],_rect[i][2],0)      
            xmin = min(xmin,x)
            xmax = max(xmax,x)
            ymin = min(ymin,y)
            ymax = max(ymax,y)
        end
        r.x,r.y,r.w,r.h = xmin,ymin,(xmax-xmin),(ymax-ymin)
    end
    return r
end

 --[[---
Returns an array of vertices describing a quad that rapresents object bounding rect as it appears into 
another coordinate system
@param targetSpace the object related to which we want to calculate the oriented bounds. 
default value refers to the top most container
@return array of position [x,y,...] for 4 points plus first point replicated. 
The array can be directely used for rendering
--]]
function DisplayObj:getOrientedBounds(targetSpace)
	local r = self:getRect(__helperRect)
    local vs = {r.x, r.y, r.x, r.y + r.h, r.x + r.w, r.y + r.h, r.x + r.w, r.y }
	
	if targetSpace ~= self then
		self:updateTransformationMatrix(targetSpace)
		for i = 1,4 do
			vs[(i-1)*2+1], vs[(i-1)*2+2] = self._transformMatrix:modelToWorld(vs[(i-1)*2+1], vs[(i-1)*2+2],0)
		end
	end
	vs[#vs+1] = vs[1]
	vs[#vs+1] = vs[2]
	return unpack(vs)
end

---Draw the oriented bounding box. Usefull for debug purpose
function DisplayObj:drawOrientedBounds()
	MOAIDraw.drawLine(self:getOrientedBounds(nil))
end

---Draw the axis aligned bound of the object as appears into top most container / stage coords
function DisplayObj:drawAABounds(drawContainer)
	--drawContainer is unused -> used only by displayObjContainer
	local r = self:getBounds(nil,__helperRect)
    MOAIDraw.drawRect(r.x,r.y,r.x+r.w,r.y+r.h)
end

--[[---
Given a x,y point in targetSpace coordinates it check if it falls inside local bounds.
@param x coordinate in targetSpace system
@param y coordinate in targetSpace system
@param targetSpace the referred coorindate system. If nil the top most container / stage
@param forTouch boolean. If true the check is done only for visible and touchable object
@return self if the hitTest is positive else nil 
--]]
function DisplayObj:hitTest(x,y,targetSpace,forTouch)
    if not forTouch or (self._visible and self._touchable) then
        local _x,_y
        if targetSpace == self then
            _x,_y = x,y
        else
            _x,_y = self:globalToLocal(x,y,targetSpace)
        end
		
        local r = self:getRect(__helperRect)
        if r:containsPoint(_x,_y) then
            return self
        end
    end
    return nil
end


