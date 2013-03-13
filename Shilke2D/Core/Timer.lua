-- Timer

Timer = class(EventDispatcher,IAnimatable)
    
function Timer:init(delay,repeatCount)
    EventDispatcher.init(self)
    self.delay = delay
    self.repeatCount = repeatCount or 1
    self:reset()
end

function Timer:start()
    self.paused = false
    self.running = true
end

function Timer:stop()
    self.paused = false
end

function Timer:reset()
    self.paused = false
    self.running = false
    self.currentCount = 0
    self.elapsedTime = 0
end

function Timer:advanceTime(deltaTime)
    if self.running and not self.paused then
        self.elapsedTime = self.elapsedTime + deltaTime
        if self.elapsedTime >= self.delay then
            self.elapsedTime = self.elapsedTime - self.delay
            self.currentCount = self.currentCount + 1
            self:dispatchEvent(TimerEvent(Event.TIMER,
                self.currentCount))
            if self.repeatCount <= 0 or self.currentCount >= 
                    self.repeatCount then
                self:dispatchEvent(Event(Event.REMOVE_FROM_JUGGLER))
                self.running = false
            end          
        end
    end
end
