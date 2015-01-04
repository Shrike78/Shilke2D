--[[---
A TweenParallel is a group of tween executed simultaneously.

@usage

p = Tween.parallel(t1,t2,t3)

where t1,t2,t3 are different tweens
--]]

local TweenParallel = class(Tween)
Tween.parallel = TweenParallel

---Constructor
--@param ... list of tweens to be parallelized
function TweenParallel:init(...)
	Tween.init(self)
	self.tweenList = {}
	self.completed = {}
	self.numOfCompleted = 0
	self:add(...)
end

---Adds tweens to the parallel list
--@param ... list of tweens to be parallelized
function TweenParallel:add(...)
	local args = {...}
	for _,v in pairs(args) do
		assert(v:is_a(Tween))
		v:addEventListener(Event.REMOVE_FROM_JUGGLER, self.onRemoveEvent,self)
		table.insert(self.tweenList,v)
	end
end

---Resets the tween and all the tweens it's handling
function TweenParallel:reset()
	Tween.reset(self)
	table.clear(self.completed)
	self.numOfCompleted = 0
	for _,t in ipairs(self.tweenList) do
		t:reset()
	end
end

function TweenParallel:onRemoveEvent(e)
	self.completed[e.sender] = true
	self.numOfCompleted = self.numOfCompleted +  1
end

function TweenParallel:_start()
	assert(#self.tweenList > 1, "tween parallel should handle at least 2 tweens")
end

function TweenParallel:_update(deltaTime)
	for _,v in pairs(self.tweenList) do
		if not self.completed[v] then
			v:advanceTime(deltaTime)
		end
	end
end

function TweenParallel:_isCompleted()
	return (self.numOfCompleted == #self.tweenList)
end
