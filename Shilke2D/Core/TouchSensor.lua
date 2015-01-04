 --[[---
Touch Sensor is an inner class used by Shilke2D to handle mouse and touch events.
Initializes the mouse/touch sensors and set the proper callbacks that can be redefined by user.

Mouse left click and move are redirected as touch events with always the same id.

Touch phases are {BEGAN, MOVING, ENDED, CANCELLED}
--]]

---Touch states
Touch = class()

Touch.BEGAN			= "began"
Touch.MOVING		= "moving"
Touch.ENDED			= "ended"
Touch.CANCELLED	= "cancelled"

function Touch:init()
	self.id = -1
	self.tapCount = 0
	self.x, self.y = 0, 0
	self.prevX, self.prevY = 0, 0
	self.deltaX, self.deltaY = 0,0		
	self.state = Touch.ENDED
end


local pointerX, pointerY = 0,0
local isTOUCHING = false
local touchBuffer = {}

local __yCorrection, __scalex, __scaley = nil, 1, 1

--[[---
Inner method.
Used to apply a transformation to point coordinates depending on stage scaling and
coordinates system
@param scalex stage width scaling factor
@param scaley stage height scaling factor
@param height height of the logical stage
--]]
function setTouchSensorCorrection(scalex, scaley, height)
    __scalex, __scaley, __yCorrection = scalex, scaley, height
end

---default touched callback. can be override just defining a function with the same name
--@param touch touch event occurred
function touched(touch)
  --override function
end

local function convertXY(x,y)
	local x = x / __scalex
	local y = y / __scaley
	if __yCorrection then
		y = __yCorrection - y
	end
	return x,y
end

--[[---
Inner event handling method to which touch and mouse events are redirected
@param eventType MOAITouchSensor event type on which redirect touch phase
@param idx the id of the current touch event in progress. on desktop id is always -1
@param x logical stage x coordinate of the touch event
@param y logical stage y coordinate of the touch event
@param tapCount for multiTap touch event the idx value doesn't change but the tapCount increase each tap
--]]
function onEvent(eventType, idx, x, y, tapCount)
	
	local x, y = convertXY(x, y)
	local touch = ObjectPool.getObj(Touch)
	
	
	touch.id = idx
	touch.tapCount = tapCount
	touch.x, touch.y = x,y
	--TODO: check the "prev / delta logic when not TOUCH_MOVE"
	
	if (eventType == MOAITouchSensor.TOUCH_DOWN) then
		touchBuffer[idx] = ObjectPool.getObj(vec2)
		touchBuffer[idx].x,touchBuffer[idx].y = x,y
		touch.prevX, touch.prevY = x,y		
		touch.deltaX, touch.deltaY = 0,0		
		touch.state = Touch.BEGAN
	elseif (eventType == MOAITouchSensor.TOUCH_MOVE) then
		touch.prevX, touch.prevY = touchBuffer[idx].x,touchBuffer[idx].y
		touch.deltaX, touch.deltaY = x - touch.prevX, y - touch.prevY		
		touch.state = Touch.MOVING
		touchBuffer[idx].x,touchBuffer[idx].y = x,y
	elseif (eventType == MOAITouchSensor.TOUCH_UP) then
		touch.prevX, touch.prevY = touchBuffer[idx].x,touchBuffer[idx].y
		touch.deltaX, touch.deltaY = x - touch.prevX, y - touch.prevY		
		touch.state = Touch.ENDED
		if touchBuffer[idx] then
			ObjectPool.recycleObj(touchBuffer[idx])
			touchBuffer[idx] = nil
		end
	elseif (eventType == MOAITouchSensor.TOUCH_CANCEL) then
		touch.prevX, touch.prevY = touchBuffer[idx].x,touchBuffer[idx].y
		touch.deltaX, touch.deltaY = x - touch.prevX, y - touch.prevY		
		touch.state = Touch.CANCELLED
		if touchBuffer[idx] then
			ObjectPool.recycleObj(touchBuffer[idx])
			touchBuffer[idx] = nil
		end
	end
	touched(touch)
	ObjectPool.recycleObj(touch)
end

---Inner function. Mouse position event handler
--@param x logical stage x coordinate of the mouse position
--@param y logical stage y coordinate of the mouse position
function onPointer(x, y)
	pointerX, pointerY = x,y
    if isTOUCHING then
        onEvent(MOAITouchSensor.TOUCH_MOVE, -1, x, y, 0)
    end
end

---Inner function. Mouse leftClick event handler
--@param down if true a touch began, else a touch ended
function onLeftClick(down)
    local x,y = pointerX, pointerY
    if down then
        onEvent(MOAITouchSensor.TOUCH_DOWN, -1, x, y, 0)
        isTOUCHING = true
    else
        onEvent(MOAITouchSensor.TOUCH_UP, -1, x, y, 0)
        isTOUCHING = false
    end
end


if MOAIInputMgr.device.pointer then
	-- mouse input
	MOAIInputMgr.device.pointer:setCallback(onPointer)
	MOAIInputMgr.device.mouseLeft:setCallback(onLeftClick)
--	MOAIInputMgr.device.mouseRight:setCallback(onClick)
	
	--[[---
	Defined only when device is mouse (pointer), mainly for debug purposes.
	It returns the mouse pointer position coordinates in Shilke2D screen space
	@return x
	@return y
	--]]
	function getPointerPosition()
		return convertXY(pointerX, pointerY)
	end
else
	--touch input
	MOAIInputMgr.device.touch:setCallback(onEvent)
end
