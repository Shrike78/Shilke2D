--[[---
TweenLoop is used to repeat n times (or infinite times) a specific 
tween

@usage

l = Tween.loop(t,2) --repeat t 2 times
l = Tween.loop(t,-1) --repeat t infinite times
--]]

local TweenLoop = class(Tween)
Tween.loop = TweenLoop

--[[---
Constructor
@param tween the tween to repeat
@param repeatCount number of times the loop must be executed. repeatCount <= 0 means infinite loop
--]]
function TweenLoop:init(tween,repeatCount)
    Tween.init(self)
    self.tween = tween
    tween:addEventListener(Event.REMOVE_FROM_JUGGLER,
                self.onRemoveEvent,self)
    self.repeatCount = repeatCount or 1
    self.currentCount = 0
end

---Resets the tween and the tween it's handling
function TweenLoop:reset()
	Tween.reset(self)
	self.currentCount = 0
	self.tween:reset()
end

function TweenLoop:onRemoveEvent(e)
    if self.currentCount < self.repeatCount or self.repeatCount <= 0 then
        self.currentCount = self.currentCount + 1
    end
	self.tween:reset()
end

function TweenLoop:_update(deltaTime)
    self.tween:advanceTime(deltaTime)
end

function TweenLoop:_isCompleted()
    return (self.currentCount == self.repeatCount) and self.repeatCount ~= 0
end
