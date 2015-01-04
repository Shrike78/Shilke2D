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
	self.tweenList = {}
	self.currentIndex = 1
	self:add(...)
end

---Add tweens to the sequence
--@param ... list of tweens to be sequenced
function TweenSequence:add(...)
	local args = {...}
	for _,v in pairs(args) do
		assert(v:is_a(Tween))
		v:addEventListener(Event.REMOVE_FROM_JUGGLER,self.onRemoveEvent,self)
		table.insert(self.tweenList,v)
	end
end

---Resets the tween and all the tweens it's handling
function TweenSequence:reset()
	Tween.reset(self)
	self.currentIndex = 1
	for _,t in ipairs(self.tweenList) do
		t:reset()
	end
end

function TweenSequence:onRemoveEvent(e)
	self.currentIndex = self.currentIndex + 1
end

function TweenSequence:_start()
	assert(#self.tweenList > 1, "tween sequence should handle at least 2 tweens")
end

function TweenSequence:_update(deltaTime)
	self.tweenList[self.currentIndex]:advanceTime(deltaTime)
end

function TweenSequence:_isCompleted()
    return (self.currentIndex > #self.tweenList)
end
