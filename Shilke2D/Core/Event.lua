--[[---
Event objects are passed as parameters to event listeners when an event occurs.
This is Shilke2D's version of the Flash Event class. 
	 
EventDispatchers create instances of this class and send them to registered listeners. 
An event object contains information that characterizes the event, most importantly the 
event type and the sender. 
--]]	 
Event = class()

Event.COMPLETED             = "__Completed__"
--- IAnimatable Objects raise this event when they need to be removed from a juggler
Event.REMOVE_FROM_JUGGLER   = "__RemoveFromJuggler__"
--- Used by DisplayObjs when hitTest for touch is true.
Event.TOUCH                 = "__Touch__"
--- Used by buttons when pressed
Event.TRIGGERED             = "__Triggered__"
--- Used by Timer when timer reach zero
Event.TIMER                 = "__timer_event__"

--[[---
Generic Event.
Base class for events, can be used to communicate a generic message. If no additional parameters are needed
it's possible to use it just defining a new eventType (a string can be good) and, optionally, a msg
@param eventType the type of the event
@param msg optional param
--]]
function Event:init(eventType,msg)
    self.type = eventType
    self.sender = nil
    self.msg = msg
end

TouchEvent = class(Event)

--[[---
Touch Event.
A touch event is generated when a touchable DisplayObj is hit.
@param touch the touch instance that led to the event generation
@param target the object that has been touched. Can differs from the sender of the event.
--]]
function TouchEvent:init(touch,target)
    Event.init(self,Event.TOUCH)
    self.touch = touch
    self.target = target
end

TimerEvent = class(Event)

--[[---
Timer Event.
A timer event is generated when a timer reach 0.
@param repeatCount the timer iteration number
--]]
function TimerEvent:init(repeatCount)
    Event.init(self,Event.TIMER)
    self.repeatCount = repeatCount
end
