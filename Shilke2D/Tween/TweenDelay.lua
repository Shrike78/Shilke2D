--[[---
Tween.delay return a TweenDelay object, that can be used either to
add a delay (pause) in a composite tween sequence or to delay a call.

A DalyedCall facility function is exposed too, that mimes the same As3
Starling class.
--]]

local TweenDelay = class(Tween)
Tween.delay = TweenDelay

---Initialization requires delay value
--@param delay the millisec to wait
function TweenDelay:init(delay)
    Tween.init(self)
    self.delay = delay or 0
end

function TweenDelay:_isCompleted()
    return (self.currentTime >= self.delay)
end

--[[---
This is just a facility to fastly create a delay tween with an onComplete 
callback function. It mimes the DelayedCall class of original
as3 Starling lib
--]]
function DelayedCall(delay,func,...)
    return Tween.delay(delay):callOnComplete(func,...)
end