-- Touch Sensor

Touch = {
	BEGAN	= "began",
	MOVING	= "moving",
	ENDED	= "ended",
	CANCEL	= "cancel"
}

local pointerX, pointerY = 0,0
local isTOUCHING = false
local touchBuffer = {}

local __yCorrection, __scalex, __scaley = nil, 1, 1

function setTouchSensorCorrection(scalex, scaley, height)
    __scalex, __scaley, __yCorrection = scalex, scaley, height
end

function touched(touch)
  --override function
end

--TODO: check the "prev / delta logic when not TOUCH_MOVE"
function onEvent(eventType, idx, x, y, tapCount)
	if __DEBUG_CALLBACKS__ then
		require('mobdebug').on()
	end
	local touch = {}
	local x = x / __scalex
	local y = y / __scaley
	
	if __yCorrection then
		y = __yCorrection - y
	end
	
	touch.id = idx
	touch.tapCount = tapCount
	touch.x, touch.y = x, y
	
	if (eventType == MOAITouchSensor.TOUCH_DOWN) then
		touchBuffer[idx] = {x,y}
		touch.prevX, touch.prevY = x,y		
		touch.deltaX, touch.deltaY = 0,0		
		touch.state = Touch.BEGAN
	elseif (eventType == MOAITouchSensor.TOUCH_MOVE) then
		touch.prevX, touch.prevY = touchBuffer[idx][1],touchBuffer[idx][2]
		touch.deltaX, touch.deltaY = x - touch.prevX, y - touch.prevY		
		touch.state = Touch.MOVING
		touchBuffer[idx] = {x,y}
	elseif (eventType == MOAITouchSensor.TOUCH_UP) then
		touch.prevX, touch.prevY = touchBuffer[idx][1],touchBuffer[idx][2]
		touch.deltaX, touch.deltaY = x - touch.prevX, y - touch.prevY		
		touch.state = Touch.ENDED
		touchBuffer[idx] = nil
	elseif (eventType == MOAITouchSensor.TOUCH_CANCEL) then
		touch.prevX, touch.prevY = touchBuffer[idx][1],touchBuffer[idx][2]
		touch.deltaX, touch.deltaY = x - touch.prevX, y - touch.prevY		
		touch.state = Touch.CANCEL
		touchBuffer[idx] = nil
	end
	touched(touch)
end

function onPointer(x, y)
	pointerX, pointerY = x,y
    if isTOUCHING then
        onEvent(MOAITouchSensor.TOUCH_MOVE, -1, x, y, 0)
    end
end

function onClick(down)
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
	MOAIInputMgr.device.mouseLeft:setCallback(onClick)
else
	MOAIInputMgr.device.touch:setCallback(onEvent)
end
