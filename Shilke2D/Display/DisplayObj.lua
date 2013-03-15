-- DisplayObj

--[[
The DisplayObject class is the base class for all objects that are
rendered on the screen.

- The Display Tree

All displayable objects are organized in a display tree.
Only objects that are part of the display tree will be displayed 
(rendered). The display tree consists of leaf nodes that will be rendered directly to the screen, and of container nodes 
(subclasses of "DisplayObjectContainer"). 

A container is simply a display object that has child nodes,
which can, again, be either leaf nodes or other containers.

A display object has properties that define its position in relation 
to its parent (x, y), as well as its rotation and scaling factors 
(scaleX, scaleY). Use the alpha and  visible properties to make an 
object translucent or invisible. Alpha value are affected by parent 
alpha values, with a multiply factor in the [0..1] range
         
- Transforming coordinates

Within the display tree, each object has its own local coordinate 
system. If you rotate a container, you rotate that coordinate system
and thus all the children of the container.

Sometimes you need to know where a certain point lies relative to 
another coordinate system. That's the purpose of the method 
getTransformationMatrix(). It will create a matrix that represents 
the transformation of a point in one coordinate system to another.
 
- Subclassing

Since DisplayObject is an abstract class, you cannot instantiate it
directly, but have to use one of its subclasses instead.

You will need to implement the following methods when you subclass
DisplayObject:

function DisplayObj:getBounds(targetSpace,resultRect)
function DisplayObj:_innerDraw()
--]]

local DEG = math.deg
local RAD = math.rad
local ABS = math.abs
local PI = math.pi
local PI2 = math.pi * 2

local min = math.min
local max = math.max
local MAX_VALUE = math.huge
local MIN_VALUE = -math.huge

local __helperRect = Rect()


DisplayObj = class(EventDispatcher)
    
function DisplayObj:init()
    EventDispatcher.init(self)
    
    self._prop = self:_createProp()
	--exact clone of transformation prop, used to calculate transformMatrix depending
	--on a specific targetSpace
    self._transformMatrix = MOAITransform.new() 
    
    self._touchable = true
    
    self._multiplyAlpha = 1
    self._alpha = 255
    
    self._name = nil
    self._parent = nil
    
	self._visible = true
end

function DisplayObj:dispose()
	EventDispatcher.dispose(self)
	self._transformMatrix = nil
	self._prop = nil
end

function DisplayObj:_createProp()
    return MOAIProp.new()
end

-- Debug Infos and __tostring redefinition
function DisplayObj:dbgInfo(recursive)
    local sb = StringBuilder()
    sb:writeln("[name = ",self._name,"]")
    sb:writeln("pivot = ",self._prop:getPiv())
    sb:writeln("position = ",self._prop:getLoc())
    sb:writeln("scale = ",self._prop:getScl())
    sb:writeln("rotation = ",self._prop:getRot())
    sb:writeln("alpha = ",self._alpha)
    sb:writeln("visible = ",(self._visible))
    sb:writeln("touchable = ",self._touchable)
            
    return sb:toString(true)
end

--It's possible (but optional) to set a name to a display obj. 
--It can be usefull for debug purpose
function DisplayObj:setName(name)
    self._name = name
end

function DisplayObj:getName()
    return self._name
end

--the method is called by a DisplayObjContainer when the DisplayObj is
--added as child
function DisplayObj:_setParent(parent)
    --assert(not parent or parent:is_a(DisplayObjContainer))
    
    self._parent = parent
    
    if parent then
        self:_setMultiplyAlpha(parent:_getMultipliedAlpha())
        self._prop:setParent(parent._prop)
--        self._prop:setNodeLink(parent._prop)
		--if not called it can happens that objects are not correctly updated since first
		--displayList change
		self._prop:forceUpdate()
    else
        self._prop:setParent(nil)
        self._multiplyAlpha = 1
    end
end

--return the displayObjContainer that contains the displayObj, if any
function DisplayObj:getParent()
    return self._parent
end

function DisplayObj:removeFromParent()
    if self._parent then
        self._prop:clearNodeLink(self._parent._prop)
        self._parent:removeChild(self)
    end
end

--return the top most displayObjContainer in the display tree
function DisplayObj:getRoot()
    local root = self
    while(root._parent) do
        root = root._parent
    end
    return root
end

-- return the top most displayObjectContainer in the display tree
-- if it's a stage, else nil
function DisplayObj:getStage()
    local root = self:getRoot()
    if root:is_a(Stage) then
        return root
    else
        return nil
    end
end

-- Setter and Getter

function DisplayObj:setVisible(visible)
	if self._visible ~= visible then
		self._visible = visible 
		if visible then
			self._prop:setCullMode(MOAIProp.CULL_NONE)
		else
			self._prop:setCullMode(MOAIProp.CULL_ALL)
		end
	end
end

function DisplayObj:isVisible()
   return self._visible
end
    
function DisplayObj:setTouchable(touchable)
    self._touchable = touchable
end

function DisplayObj:isTouchable()
   return self._touchable
end

--setMultiplyAlpha set the alpha value of the parent container (already
--modified by his current multiplyalpha value)
function DisplayObj:_setMultiplyAlpha(a)
    self._multiplyAlpha = a / 255
    self._prop:setAttr(MOAIColor.ATTR_A_COL, (self._alpha / 255) * self._multiplyAlpha)
end

--getMultipliedAlpha return the [0..1] multiply value provided by 
--the parent container, multiply the [0..255] alpha value of the 
--displayObj
function DisplayObj:_getMultipliedAlpha()
    return self._multiplyAlpha * self._alpha
--  return self._prop:getAttr(MOAIColor.ATTR_A_COL)  
end


-- public Setter and Getter

-- Seek and Move Helpers
function DisplayObj:seekProp(setter,getter,endValue,time,transition)
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(self,time,transition)
	tween:seekEx(setter,getter,endValue)
	return tween
end

function DisplayObj:moveProp(setter,getter,deltaValue,time,transition)	
	local transition = transition or Transition.LINEAR
	local tween = Tween.ease(self,time,transition)
	tween:moveEx(setter,getter,deltaValue)
	return tween
end

--alpha [0..255]
function DisplayObj:setAlpha(a)
    self._alpha = math.clamp(a,0,255)
    self._prop:setAttr(MOAIColor.ATTR_A_COL, (self._alpha / 255) * self._multiplyAlpha)
end

function DisplayObj:getAlpha()
   return self._alpha
end

function DisplayObj:seekAlpha(a,time,transition)
	return self:seekProp(self.setAlpha,self.getAlpha,a,time,transition)
end

function DisplayObj:moveAlpha(a,time,transition)
	return self:moveProp(self.setAlpha,self.getAlpha,a,time,transition)
end

-- it's possible to set only r,g,b value or also alpha value overriding the setAlpha method
function DisplayObj:setColor(r,g,b,a)
	if type(r) == 'number' then
		local r = r/255
		local g = g/255
		local b = b/255
		if a then
			self._alpha = a
		end
		self._prop:setColor(r,g,b,(self._alpha / 255) * self._multiplyAlpha)
	else
		local _r = r.r/255
		local _g = r.g/255
		local _b = r.b/255
		self._alpha = r.a
		self._prop:setColor(_r,_g,_b,(self._alpha / 255) * self._multiplyAlpha)
	end
end

function DisplayObj:getColor()
	local r = self._prop:getAttr(MOAIColor.ATTR_R_COL)  
	local g = self._prop:getAttr(MOAIColor.ATTR_G_COL)  
	local b = self._prop:getAttr(MOAIColor.ATTR_B_COL)  
	return Color(r*255,g*255,b*255, self._alpha)
end

function DisplayObj:seekColor(c,time,transition)
	return self:seekProp(self.setColor,self.getColor,c,time,transition)
end

function DisplayObj:moveColor(c,time,transition)
	return self:moveProp(self.setColor,self.getColor,c,time,transition)
end

function DisplayObj:setPivot(x,y)
    self._prop:setPiv(x,y,0)
end

function DisplayObj:getPivot()
    local x,y = self._prop:getPiv()
    return x,y
end

function DisplayObj:setPivotX(x)
	self._prop:setAttr(MOAITransform.ATTR_X_PIV,x)
end

function DisplayObj:getPivotX()
   return self._prop:getAttr(MOAITransform.ATTR_X_PIV)
end

function DisplayObj:setPivotY(y)
	self._prop:setAttr(MOAITransform.ATTR_Y_PIV,y)
end

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
function DisplayObj:setPosition(x,y)
    self._prop:setLoc(x,y,0)
end

function DisplayObj:getPosition()
    local x,y = self._prop:getLoc()
    return x,y
end

function DisplayObj:setPosition_v2(v)
    self._prop:setLoc(v.x,v.y,0)
end

function DisplayObj:getPosition_v2()
	local x,y = self._prop:getLoc()
    return vec2(x,y)
end

function DisplayObj:setPositionX(x)
    self._prop:setAttr(MOAITransform.ATTR_X_LOC,x)
end

function DisplayObj:getPositionX()
    return self._prop:getAttr(MOAITransform.ATTR_X_LOC)
end

function DisplayObj:setPositionY(y)
    self._prop:setAttr(MOAITransform.ATTR_Y_LOC,y)
end

function DisplayObj:getPositionY()
    return self._prop:getAttr(MOAITransform.ATTR_Y_LOC)
end 

function DisplayObj:translate(x,y)
    self._prop:addLoc(x,y,0)
end

function DisplayObj:seekPosition(x,y,time,transition)
	return self:seekProp(self.setPosition_v2,self.getPosition_v2,vec2(x,y),time,transition)
end

function DisplayObj:movePosition(x,y,time,transition)
	return self:moveProp(self.setPosition_v2,self.getPosition_v2,vec2(x,y),time,transition)
end

-- used to follow another displayobj
function DisplayObj:seekTarget(target,time,transition)
	local transition = transition or Transition.LINEAR
	local juggler = juggler or Shilke2D.current.juggler
	local tween = Tween.ease(self,time,transition)
	tween:followEx(self.setPosition_v2,self.getPosition_v2,target,target.getPosition_v2)
	--juggler:add(tween)
	return tween
end

-- rotation angle is expressed in radians
function DisplayObj:setRotation(r)
    --move into range [-180 deg, +180 deg]
    while (r < -PI) do r = r + PI2 end
    while (r >  PI) do r = r - PI2 end
    self._prop:setAttr(MOAITransform.ATTR_Z_ROT,DEG(r))
end

function DisplayObj:getRotation()
    return RAD(self._prop:getAttr(MOAITransform.ATTR_Z_ROT))
end

function DisplayObj:seekRotation(r,time,transition)
	return self:seekProp(self.setRotation,self.getRotation,r,time,transition)
end

function DisplayObj:moveRotation(r,time,transition)
	return self:moveProp(self.setRotation,self.getRotation,r,time,transition)
end

function DisplayObj:setScale(x,y)
    self._prop:setScl(x,y)
end

function DisplayObj:getScale()
    local x,y = self._prop:getScl()
    return x,y
end

function DisplayObj:setScale_v2(v)
    self._prop:setScl(v.x,v.y)
end

function DisplayObj:getScale_v2()
    local x,y = self._prop:getScl()
    return vec2(x,y)
end

function DisplayObj:setScaleX(s)
    self._prop:setAttr(MOAITransform.ATTR_X_SCL,s)
end

function DisplayObj:getScaleX()
    return self._prop:getAttr(MOAITransform.ATTR_X_SCL)
end

function DisplayObj:setScaleY(s)
    self._prop:setAttr(MOAITransform.ATTR_Y_SCL,s)
end

function DisplayObj:getScaleY()
    return self._prop:getAttr(MOAITransform.ATTR_Y_SCL)
end

function DisplayObj:seekScale(sx,sy,time,transition)
	return self:seekProp(self.setScale_v2,self.getScale_v2,vec2(sx,sy),time,transition)
end

function DisplayObj:moveScale(sx,sy,time,transition)
	return self:moveProp(self.setScale_v2,self.getScale_v2,vec2(sx,sy),time,transition)
end


--[[
    
    Note: if the passed obj is not an ancestor an error occurs
    
    to have the same functionality of flash/shilke2D is it possible 
    to expose a specific function like "find common ancestor" or 
    similar, calculate the transf matrix of both the objs related 
    to the common ancestor, and use them to calculate the final
    matrix. but being expensive it's preferrable to split the 2
    functionality
--]]
--[[
	self._transformMatrix:setPiv(x,y,0)
    self._transformMatrix:setLoc(x,y,0)
    self._transformMatrix:setAttr(MOAITransform.ATTR_Z_ROT,DEG(r))
    self._transformMatrix:setScl(x,y)
--]]
function DisplayObj:updateTransformationMatrix(targetSpace)
	
	if targetSpace == self then
		self._transformMatrix:setParent(nil)
		self._transformMatrix:setPiv(0,0,0)
		self._transformMatrix:setLoc(0,0,0)
		self._transformMatrix:setScl(1,1)
		self._transformMatrix:setAttr(MOAITransform.ATTR_Z_ROT,0)
		self._transformMatrix:forceUpdate()
		return
	end
	
	if self._parent then
		self._parent:updateTransformationMatrix(targetSpace)
		self._transformMatrix:setParent(self._parent._transformMatrix)
		self._transformMatrix:setPiv(self._prop:getPiv())
		self._transformMatrix:setLoc(self._prop:getLoc())
		self._transformMatrix:setScl(self._prop:getScl())
		self._transformMatrix:setAttr(MOAITransform.ATTR_Z_ROT,
			self._prop:getAttr(MOAITransform.ATTR_Z_ROT))
		self._transformMatrix:forceUpdate()
		return
	end
	
	if not targetSpace then
		return
	else
		error("the targetSpace is not an ancestor of the current obj")
	end
end	

--Transforms a point from the local coordinate system to 
--global coordinates. targetSpace define the destination 
--space of the transformation. If nil is the screenspace
--(== stage)
function DisplayObj:localToGlobal(x,y,targetSpace)
    self:updateTransformationMatrix(targetSpace)
    local x,y,z = self._transformMatrix:modelToWorld(x,y,0)
	return x,y
end

--Transforms a point from global coordinates to the local 
--coordinate system. targetSpace define the source 
--space of the transformation, to where x,y belongs
--If nil is considered to be the screenspace (== stage)
function DisplayObj:globalToLocal(x,y,targetSpace)
    self:updateTransformationMatrix(targetSpace)
    local x,y,z = self._transformMatrix:worldToModel(x,y,0)
	return x,y
end


-- SetGlobalPos is used to set an absolut position related to stage 
-- coords, do not dependant on displayList. Is usefull for drag and 
-- drop feature and so on
function DisplayObj:setGlobalPosition(x,y)
	local _x,_y
	if self._parent then
		_x,_y = self._parent:globalToLocal(x,y)
	else
		_x,_y = x,y
	end
    self._prop:setLoc(_x,_y,0)
    self._transformMatrix:setLoc(_x,_y,0)
end

-- return global position of the displayObj, related to stage coords
function DisplayObj:getGlobalPosition()
	return self:localToGlobal(self._prop:getLoc())
end

function DisplayObj:globalTranslate(dx,dy)
	local px,py = self._prop:getPiv()
	local x,y = self:localToGlobal(px,py)
	x = x + dx
	y = y + dy
	self:setGlobalPosition(x,y)
end

function DisplayObj:getRect(resultRect)
    error("method must be overridden")
end


function DisplayObj:getWidth()
	return self:getBounds(self._parent,__helperRect).w
end

function DisplayObj:getHeight()
	return self:getBounds(self._parent,__helperRect).h
end

--Returns a rectangle that completely encloses the object as it 
--appears in another coordinate system. The method must be override
--by subclasses.
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

function DisplayObj:getOrientedBounds(targetSpace,resultRect)
	local r = self:getRect(resultRect)
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

function DisplayObj:drawOrientedBounds()
	MOAIDraw.drawLine(self:getOrientedBounds(nil,__helperRect))
end

function DisplayObj:drawAABounds(drawContainer)
	local r = self:getBounds(nil,__helperRect)
    MOAIDraw.drawRect(r.x,r.y,r.x+r.w,r.y+r.h)
end

--the method should be override by DisplayObjContainer to handle
--sub objs hitTest, following inverse render pipeline
--Moreover should be aligned to the shilke2D version where is possible
--to define a "forTouch" param to handle touchable state, and the
--return value should became the target display obj
function DisplayObj:hitTest(x,y,targetSpace,forTouch)
    if not forTouch or (self._visible and self._touchable) then
        local _x,_y
        if targetSpace == self then
            _x,_y = x,y
        else
            _x,_y = self:globalToLocal(x,y,targetSpace)
        end
		
        local r = self:getBounds(self,__helperRect)
        if r:containsPoint(_x,_y) then
            return self
        end
    end
    return nil
end


