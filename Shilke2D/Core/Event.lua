-- Event

Event = class()

Event.REMOVE_FROM_JUGGLER   = "__RemoveFromJuggler__"
Event.COMPLETED             = "__Completed__"
Event.TOUCH                 = "__Touch__"
Event.TRIGGERED             = "__Triggered__"
Event.TIMER                 = "__timer_event__"

function Event:init(eventType,msg)
    self.type = eventType
    self.sender = nil
    self.msg = msg
end

TouchEvent = class(Event)

function TouchEvent:init(touch,target)
    Event.init(self,Event.TOUCH)
    self.touch = touch
    self.target = target
end

TimerEvent = class(Event)

function TimerEvent:init(repeatCount)
    Event.init(self,Event.TIMER)
    self.repeatCount = repeatCount
end
