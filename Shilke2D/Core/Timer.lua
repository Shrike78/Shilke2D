 --[[---
Timer class is the equivalent of as3 Timer. 
Each timer can be scheduled to run multiple times, even infinite.
It's possible to register as listener for timer events.
A Timer can be started, stopped and paused
--]]
Timer = class(EventDispatcher,IAnimatable)
	
 --[[---
Timer initialization.
@param delay the duration of each countdown
@param repeatCount the number of iteration. Defaul is 1. 0 or negative values means Infinite
--]] 
function Timer:init(delay,repeatCount)
	EventDispatcher.init(self)
	self.delay = delay
	self.repeatCount = repeatCount or 1
	self:reset()
end

---Starts the timer, if it is not already running.
function Timer:start()
	self.running = true
end

---Resets and start again the timer
function Timer:restart()
	self.currentCount = 0
	self.elapsedTime = 0
	self.running = true
end

---Stops the timer, if it is running.
function Timer:stop()
    self.running = false
end

--[[---
Stops the timer, if it is running.
Sets the currentCount property and the elapsedTime property back to 0, 
like the reset button of a stopwatch,  to 
--]]
function Timer:reset()
	self.running = false
	self.currentCount = 0
	self.elapsedTime = 0
end

---IAnimatable update method
function Timer:advanceTime(deltaTime)
	if self.running then
		self.elapsedTime = self.elapsedTime + deltaTime
		if self.elapsedTime >= self.delay then
			self.elapsedTime = self.elapsedTime - self.delay
			self.currentCount = self.currentCount + 1
			local timerEvent = ObjectPool.getObj(TimerEvent)
			timerEvent.repeatCount = self.currentCount
			self:dispatchEvent(timerEvent)
			ObjectPool.recycleObj(timerEvent)
			if self.repeatCount <= 0 or self.currentCount >= 
					self.repeatCount then
				self:dispatchEventByType(Event.REMOVE_FROM_JUGGLER)
				self.running = false
			end          
		end
	end
end
