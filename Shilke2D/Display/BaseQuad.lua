--[[---
BaseQuad is a displayObj, base class for all the displayObject that can be rapresented by a quad 
(so Quad, Image, Movieclip and so on)

Is not a real 'renderable' because has no MOAIDeck binded to the main prop, it can be considered 
as a middle class that has no meeaning to be instantiated by itself.

BaseQuad allows different pivotMode. Default PivotMode is PivotMode.CENTER               
--]]

---PivotMode function
PivotMode = 
{
	CUSTOM 			= 1,
	BOTTOM_LEFT 	= 2,
	BOTTOM_CENTER 	= 3,
	BOTTOM_RIGHT 	= 4,
	CENTER_LEFT 	= 5,
	CENTER 			= 6,
	CENTER_RIGHT 	= 7,
	TOP_LEFT 		= 8,
	TOP_CENTER 		= 9,
	TOP_RIGHT 		= 10
}


BaseQuad = class(DisplayObj)

--[[
The pivot can be custom (by calling setPivot/setPivotX,Y) or
fixed (center,top_left,bottom_left)
to handle fixed pivot, each time a geometric change happens
there must be a call to a specific function that reset the pivot, 
depending on the new shape of the object.
--]]
function BaseQuad:_doNothing()
end

function BaseQuad:_pivotModeBL()
   DisplayObj.setPivot(self, 0, __USE_SIMULATION_COORDS__ and 0 or self._height)
end

function BaseQuad:_pivotModeBC()
   DisplayObj.setPivot(self, self._width*0.5, __USE_SIMULATION_COORDS__ and 0 or self._height)
end

function BaseQuad:_pivotModeBR()
   DisplayObj.setPivot(self, self._width, __USE_SIMULATION_COORDS__ and 0 or self._height)
end

function BaseQuad:_pivotModeCL()
	DisplayObj.setPivot(self, 0, self._height*0.5)
end

function BaseQuad:_pivotModeC()
	DisplayObj.setPivot(self,self._width*0.5, self._height*0.5)
end

function BaseQuad:_pivotModeCR()
	DisplayObj.setPivot(self, self._width, self._height*0.5)
end

function BaseQuad:_pivotModeTL()
	DisplayObj.setPivot(self, 0, __USE_SIMULATION_COORDS__ and self._height or 0)
end

function BaseQuad:_pivotModeTC()
	DisplayObj.setPivot(self, self._width*0.5, __USE_SIMULATION_COORDS__ and self._height or 0)
end

function BaseQuad:_pivotModeTR()
	DisplayObj.setPivot(self, self._width, __USE_SIMULATION_COORDS__ and self._height or 0)
end

--ordered by PivotMode enum values
BaseQuad.__pivotModeFunctions = {
	BaseQuad._doNothing,	--"CUSTOM"

	BaseQuad._pivotModeBL,	--"BOTTOM_LEFT"
	BaseQuad._pivotModeBC,	--"BOTTOM_CENTER"
	BaseQuad._pivotModeBR,	--"BOTTOM_RIGHT"

	BaseQuad._pivotModeCL,	--"CENTER_LEFT"
	BaseQuad._pivotModeC,	--"CENTER"
	BaseQuad._pivotModeCR,	--"CENTER_RIGHT"

	BaseQuad._pivotModeTL,	--"TOP_LEFT"
	BaseQuad._pivotModeTC,	--"TOP_CENTER"
	BaseQuad._pivotModeTR	--"TOP_RIGHT"
}

---Initialization.
--@param width widht of the quad
--@param height height of the quad
--@param pivotMode by default PivotMode.CENTER
function BaseQuad:init(width,height,pivotMode)
	DisplayObj.init(self)
	self._width = width or 0
	self._height = height or 0
	local pivotMode = pivotMode or PivotMode.CENTER
	self:setPivotMode(pivotMode)
end

---Set the size of the object.
--If pivotMode is not custom then it recalculate pivot depending on pivotMode logic / function
--@param width widht of the quad
--@param height height of the quad
function BaseQuad:setSize(width,height)
	self._width = width
	self._height = height
	BaseQuad.__pivotModeFunctions[self._pivotMode](self)
end

function BaseQuad:getSize(targetSpace)
	if not targetSpace or targetSpace == self then
		return self._width, self._height
	else
		return DisplayObj.getSize(self, targetSpace)
	end
end

function BaseQuad:getWidth(targetSpace)
	if not targetSpace or targetSpace == self then
		return self._width
	else
		return DisplayObj.getWidth(self, targetSpace)
	end
end

function BaseQuad:getHeight(targetSpace)
	if not targetSpace or targetSpace == self then
		return self._height
	else
		return DisplayObj.getHeight(self, targetSpace)
	end
end

---Set the pivotMode object.
function BaseQuad:setPivotMode(pivotMode)
    self._pivotMode = pivotMode
    BaseQuad.__pivotModeFunctions[pivotMode](self)
end

---Returns current pivotMode.
--@return object pivotMode
function BaseQuad:getPivotMode()
    return self._pivotMode
end

--[[---
Set pivot coordinates.
A CUSTOM pivot point is not recalculated when object size changes
@param x pivot x coordinate
@param y pivot y coordinate
--]]
function BaseQuad:setPivot(x,y)
	if self._pivotMode ~= PivotMode.CUSTOM then
		self:setPivotMode(PivotMode.CUSTOM)
	end
	self._prop:setPiv(x,y,0)
end

--[[---
Set Pivot x position
A CUSTOM pivot point is not recalculated when object size changes
@param x pivot x coordinate
--]]
function BaseQuad:setPivotX(x)
	if self._pivotMode ~= PivotMode.CUSTOM then
		self:setPivotMode(PivotMode.CUSTOM)
	end
	self._prop:setAttr(MOAITransform.ATTR_X_PIV, x)    
end

--[[---
Set Pivot y position
A CUSTOM pivot point is not recalculated when object size changes
@param y pivot y coordinate
--]]
function BaseQuad:setPivotY(y)
	if self._pivotMode ~= PivotMode.CUSTOM then
		self:setPivotMode(PivotMode.CUSTOM)
	end
	self._prop:setAttr(MOAITransform.ATTR_Y_PIV, y)
end


---Returns the rect defined by obj widht and height, centered in 0,0
--@param resultRect helper rect that can be set avoiding creation of a new rect
function BaseQuad:getRect(resultRect)
    local r = resultRect or Rect()
	r.x = 0
	r.y = 0
	r.w = self._width
	r.h = self._height
	return r
end

