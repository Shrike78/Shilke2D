--[[---
BaseQuad is a displayObj, base class for all the displayObject that can be rapresented by a quad 
of fixed size (so Quad, Image, Movieclip and so on)

It's not a real 'renderable' because has no MOAIDeck binded to the main prop, it can be considered 
as a middle class that has no meeaning to be instantiated by itself.

BaseQuad allows different pivotMode. Default PivotMode is PivotMode.CENTER               
--]]

---
-- Pivot Modes
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

-- pivotModeMultipliers are constant pairs of width/height multipliers used to set
-- pivot based on required pivotmode
local __pivotModeMultipliers
--  based on coordinate system, a specific pivot mode can be considered as 'optimized' because
--  the pivot is always forced to 0,0 (so it doesn't really change when size changes)
local __optimizedPivotMode

if __USE_SIMULATION_COORDS__ then
	
	__optimizedPivotMode = PivotMode.BOTTOM_LEFT
	
	__pivotModeMultipliers = {
		nil,	--"CUSTOM"

		{0,0},	--"BOTTOM_LEFT"
		{.5,0},	--"BOTTOM_CENTER"
		{1,0},	--"BOTTOM_RIGHT"

		{0,.5},	--"CENTER_LEFT"
		{.5,.5},--"CENTER"
		{1,.5},	--"CENTER_RIGHT"

		{0,1},	--"TOP_LEFT"
		{.5,1},	--"TOP_CENTER"
		{1,1}	--"TOP_RIGHT"
	}
else
	__optimizedPivotMode = PivotMode.TOP_LEFT
	
	__pivotModeMultipliers = {
		nil,	--"CUSTOM"

		{0,1},	--"BOTTOM_LEFT"
		{.5,1},	--"BOTTOM_CENTER"
		{1,1},	--"BOTTOM_RIGHT"

		{0,.5},	--"CENTER_LEFT"
		{.5,.5},--"CENTER"
		{1,.5},	--"CENTER_RIGHT"

		{0,0},	--"TOP_LEFT"
		{.5,0},	--"TOP_CENTER"
		{1,0}	--"TOP_RIGHT"
	}
end

---
-- Initialization.
-- @param width widht of the quad
-- @param height height of the quad
-- @param pivotMode by default PivotMode.CENTER
function BaseQuad:init(width,height,pivotMode)
	DisplayObj.init(self)
	self._width = width or 0
	self._height = height or 0
	local pivotMode = pivotMode or PivotMode.CENTER
	self:setPivotMode(pivotMode)
end

function BaseQuad:getSize(targetSpace)
	if not targetSpace or targetSpace == self then
		return self._width, self._height
	end
	return DisplayObj.getSize(self, targetSpace)
end

function BaseQuad:getWidth(targetSpace)
	if not targetSpace or targetSpace == self then
		return self._width
	end
	return DisplayObj.getWidth(self, targetSpace)
end

function BaseQuad:getHeight(targetSpace)
	if not targetSpace or targetSpace == self then
		return self._height
	end
	return DisplayObj.getHeight(self, targetSpace)
end

---
-- Set the size of the object.
-- If a specific pivot mode is set, the pivot is adjusted based on new size
-- @param width widht of the quad
-- @param height height of the quad
function BaseQuad:setSize(width,height)
	self._width = width
	self._height = height
	if self._pivotMode == __optimizedPivotMode or self._pivotMode == PivotMode.CUSTOM then
		return
	end
	local multipliers = __pivotModeMultipliers[self._pivotMode]
	self._prop:setPiv(multipliers[1] * width, multipliers[2] * height,0)
end

---
-- Set the pivotMode object.
-- @tparam PivotMode pivotMode
function BaseQuad:setPivotMode(pivotMode)
    self._pivotMode = pivotMode
	if pivotMode == PivotMode.CUSTOM then
		return
	end
	local multipliers = __pivotModeMultipliers[self._pivotMode]
	self._prop:setPiv(multipliers[1] * self._width, multipliers[2] * self._height,0)
end

---
-- Returns current pivotMode.
-- @return object pivotMode
function BaseQuad:getPivotMode()
    return self._pivotMode
end

---
-- Set pivot coordinates.
-- A CUSTOM pivot point is not recalculated when object size changes
-- @param x pivot x coordinate
-- @param y pivot y coordinate
function BaseQuad:setPivot(x,y)
	self._pivotMode = PivotMode.CUSTOM
	self._prop:setPiv(x,y,0)
end

---
-- Set Pivot x position
-- A CUSTOM pivot point is not recalculated when object size changes
-- @param x pivot x coordinate
function BaseQuad:setPivotX(x)
	self._pivotMode = PivotMode.CUSTOM
	self._prop:setAttr(MOAITransform.ATTR_X_PIV, x)    
end

---
-- Set Pivot y position
-- A CUSTOM pivot point is not recalculated when object size changes
-- @param y pivot y coordinate
function BaseQuad:setPivotY(y)
	self._pivotMode = PivotMode.CUSTOM
	self._prop:setAttr(MOAITransform.ATTR_Y_PIV, y)
end


---
-- Returns the rect defined by obj widht and height, centered in 0,0
-- @param resultRect helper rect that can be set avoiding creation of a new rect
function BaseQuad:getRect(resultRect)
    local r = resultRect or Rect()
	r.x = 0
	r.y = 0
	r.w = self._width
	r.h = self._height
	return r
end

