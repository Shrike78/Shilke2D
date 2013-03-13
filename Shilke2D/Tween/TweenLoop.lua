-- TweenLoop

--[[
TweenLoop is used to repeat n times (or infinite times) a specific 
tween

usage:

l = Tween.loop(t,2) --repeat t 2 times
l = Tween.loop(t,-1) --repeat t infinite times
--]]

local TweenLoop = class(Tween)
Tween.loop = TweenLoop

-- tween: the tween to repeat
-- repeatNum: positive number or negative value for infinite repetition
function TweenLoop:init(tween,repeatCount)
    Tween.init(self)
    assert(tween:is_a(Tween))
    assert(repeatCount and repeatCount~= 0,
        "repeatCount cannot be null or 0")
    self.tween = tween
    tween:addEventListener(Event.REMOVE_FROM_JUGGLER,
                self.onRemoveEvent,self)
    self.repeatCount = repeatCount
    self.currentCount = 0
end

function TweenLoop:reset()
	Tween.reset(self)
	self.currentCount = 0
	self.tween:reset()
end

function TweenLoop:onRemoveEvent(e)
    if self.currentCount < self.repeatCount then
        self.currentCount = self.currentCount + 1
    end
	self.tween:reset()
end

function TweenLoop:_update(deltaTime)
    self.tween:advanceTime(deltaTime)
end

function TweenLoop:_isCompleted()
    return (self.currentCount == self.repeatCount)
end
