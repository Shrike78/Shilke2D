-- FixedSizeObject

--[[
FixedSizeObject allows different pivotMode:

    "CUSTOM"      	: manually set x,y coordinates
	
    "BOTTOM_LEFT" 	: the pivotPoint is always the bottom left point of 
						the bound rect
    "BOTTOM_CENTER" : the pivotPoint is always the bottom center point of 
						the bound rect
    "BOTTOM_RIGHT"	: the pivotPoint is always the bottom right point of 
						the bound rect
 
	"CENTER_LEFT" 	: the pivotPoint is always the center left point of 
						the bound rect
    "CENTER"      	: the pivotPoint is always the center point of the 
						bound rect
    "CENTER_RIGHT" 	: the pivotPoint is always the center right point of 
						the bound rect
	
    "TOP_LEFT"    	: the pivotPoint is always the top left point of the 
						bound rect
    "TOP_CENTER" : the pivotPoint is always the top center point of 
						the bound rect
    "TOP_RIGHT"  	: the pivotPoint is always the top right point of the 
						bound rect
                    
PivotMode.CENTER is the most performant mode (because it relies on
mesh:setRect) and for this reason is the default mode.
--]]

PivotMode = {
    CUSTOM = 1,
	
    BOTTOM_LEFT = 2,
    BOTTOM_CENTER = 3,
    BOTTOM_RIGHT = 4,
    
	CENTER_LEFT = 5,
    CENTER = 6, 
	CENTER_RIGHT = 7,
	
    TOP_LEFT = 8,
    TOP_CENTER = 9,
    TOP_RIGHT = 10
}


FixedSizeObject = class(DisplayObj)


--The pivot can be custom (by calling setPivot/setPivotX,Y) or
--fixed (center,top_left,bottom_left)
--to handle fixed pivot, each time a geometric change happens
--there must be a call to a specific function that reset the pivot, 
--depending on the new shape of the object.
function FixedSizeObject:_doNothing()
end

local __height_correction__

if __USE_SIMULATION_COORDS__ then
	__height_correction__ = -1
else
	__height_correction__ = 1
end

function FixedSizeObject:_pivotModeBL()
   DisplayObj.setPivot(self, -self._width/2, __height_correction__ * self._height/2)
end

function FixedSizeObject:_pivotModeBC()
   DisplayObj.setPivot(self, 0, __height_correction__ * self._height/2)
end

function FixedSizeObject:_pivotModeBR()
   DisplayObj.setPivot(self, self._width/2, __height_correction__ * self._height/2)
end

function FixedSizeObject:_pivotModeCL()
	DisplayObj.setPivot(self, -self._width/2, 0)
end

function FixedSizeObject:_pivotModeC()
	DisplayObj.setPivot(self,0,0)
end

function FixedSizeObject:_pivotModeCR()
	DisplayObj.setPivot(self, self._width/2,0)
end

function FixedSizeObject:_pivotModeTL()
	DisplayObj.setPivot(self, -self._width/2, -__height_correction__ * self._height/2)
end

function FixedSizeObject:_pivotModeTC()
	DisplayObj.setPivot(self, 0, -__height_correction__ * self._height/2)
end

function FixedSizeObject:_pivotModeTR()
	DisplayObj.setPivot(self, self._width/2, -__height_correction__ * self._height/2)
end

--ordered by PivotMode enum values
FixedSizeObject.__pivotModeFunctions = {
        FixedSizeObject._doNothing,		--"CUSTOM"
		
        FixedSizeObject._pivotModeBL,	--"BOTTOM_LEFT"
        FixedSizeObject._pivotModeBC,	--"BOTTOM_CENTER"
        FixedSizeObject._pivotModeBR,	--"BOTTOM_RIGHT"
  
		FixedSizeObject._pivotModeCL,	--"CENTER_LEFT"
		FixedSizeObject._pivotModeC,	--"CENTER"
		FixedSizeObject._pivotModeCR,	--"CENTER_RIGHT"
		
        FixedSizeObject._pivotModeTL,	--"TOP_LEFT"
        FixedSizeObject._pivotModeTC,	--"TOP_CENTER"
        FixedSizeObject._pivotModeTR	--"TOP_RIGHT"
}

function FixedSizeObject:init(width,height,pivotMode)
	DisplayObj.init(self)
	self._width = width
	self._height = height
	local pivotMode = pivotMode or PivotMode.CENTER
	self:setPivotMode(pivotMode)
end

function FixedSizeObject:setSize(width,height)
	self._width = width
	self._height = height
    FixedSizeObject.__pivotModeFunctions[self._pivotMode](self)
end

function FixedSizeObject:setPivotMode(pivotMode)
    self._pivotMode = pivotMode
    FixedSizeObject.__pivotModeFunctions[pivotMode](self)
end

function FixedSizeObject:getPivotMode()
    return self._pivotMode
end

function FixedSizeObject:setPivot(x,y)
    self:setPivotMode(PivotMode.CUSTOM)
	self._prop:setPiv(x-self._width/2 ,y - self._height/2, 0)
end

function FixedSizeObject:getPivot()
    local x,y = self._prop:getPiv()
    return x + self._width/2, y + self._height/2
end

function FixedSizeObject:setPivotX(x)
    self:setPivotMode(PivotMode.CUSTOM)
	self._prop:setAttr(MOAITransform.ATTR_X_PIV, x - self._width/2)    
end

function FixedSizeObject:getPivotX()
   return self._prop:getAttr(MOAITransform.ATTR_X_PIV) + self._width/2
end

function FixedSizeObject:setPivotY(y)
    self:setPivotMode(PivotMode.CUSTOM)
	self._prop:setAttr(MOAITransform.ATTR_Y_PIV, y - self._height/2)
end

function FixedSizeObject:getPivotY()
   return self._prop:getAttr(MOAITransform.ATTR_Y_PIV) + self._height/2
end

function FixedSizeObject:getRect(resultRect)
    local r = resultRect or Rect()
	r.x = -self._width/2
	r.y = -self._height/2
	r.w = self._width
	r.h = self._height
	return r
end

local RAD = math.rad

function FixedSizeObject:getWidth()
    local w,h = self._width,self._height
    if self._parent then
      local r = RAD(self._prop:getAttr(MOAITransform.ATTR_Z_ROT))
      local sx,sy = self._prop:getScl() 
      w = math.abs( sx * w * math.cos(r)) + math.abs(sy * h * math.sin(r))
    end
    return w
end

function FixedSizeObject:getHeight()
    local w,h = self._width,self._height
    if self._parent then
      local r = RAD(self._prop:getAttr(MOAITransform.ATTR_Z_ROT))
      local sx,sy = self._prop:getScl() 
      h = math.abs( sx * w * math.sin(r)) + math.abs(sy * h * math.cos(r))
    end
    return h
end

