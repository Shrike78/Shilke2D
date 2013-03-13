-- TweenParallel

--[[
A TweenParallel is a group of tween executed simultaneously.

usage:

p = Tween.parallel(t1,t2,t3)

where t1,t2,t3 are different tweens
--]]

local TweenParallel = class(Tween)
Tween.parallel = TweenParallel

function TweenParallel:init(...)
    Tween.init(self)
    local args = {...}
    assert(#args>1,"a tween parallel must contains at least 2 elements")
    self.list = {}
    self.completed = {}
    self.numOfCompleted = 0
    for _,v in pairs(args) do
        assert(v:is_a(Tween))
        v:addEventListener(Event.REMOVE_FROM_JUGGLER,
                    self.onRemoveEvent,self)
        table.insert(self.list,v)
    end
end

function TweenParallel:reset()
	Tween.reset(self)
	table.clear(self.completed)
    self.numOfCompleted = 0
	for _,t in ipairs(self.list) do
		t:reset()
	end
end

function TweenParallel:onRemoveEvent(e)
    self.completed[e.sender] = true
    self.numOfCompleted = self.numOfCompleted +  1
end

function TweenParallel:_update(deltaTime)
    for _,v in pairs(self.list) do
        if not self.completed[v] then
            v:advanceTime(deltaTime)
        end
    end
end

function TweenParallel:_isCompleted()
    return (self.numOfCompleted == #self.list)
end
