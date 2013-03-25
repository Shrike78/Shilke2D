--[[---
A TweenSequence is a group of tween executed sequentially.

@usage

p = Tween.sequence(t1,t2,t3)

where t1,t2,t3 are different tweens
--]]

local TweenSequence = class(Tween)
Tween.sequence = TweenSequence

---Constructor
--@param ... list of tweens to be sequenced
function TweenSequence:init(...)
    Tween.init(self)
    local args = {...}
    assert(#args>1,"a tween list must contains at least 2 elements")
    self.list = {}
    for _,v in pairs(args) do
        assert(v:is_a(Tween))
        v:addEventListener(Event.REMOVE_FROM_JUGGLER,self.onRemoveEvent,self)
        table.insert(self.list,v)
    end
    self.currentIndex = 1
end

---Resets the tween and all the tweens it's handling
function TweenSequence:reset()
	Tween.reset(self)
	self.currentIndex = 1
	for _,t in ipairs(self.list) do
		t:reset()
	end
end

function TweenSequence:onRemoveEvent(e)
    self.currentIndex = self.currentIndex + 1
end

function TweenSequence:_update(deltaTime)
    self.list[self.currentIndex]:advanceTime(deltaTime)
end

function TweenSequence:_isCompleted()
    return (self.currentIndex > #self.list)
end
