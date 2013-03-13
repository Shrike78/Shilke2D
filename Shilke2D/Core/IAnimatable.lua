-- IAnimatable

--[[
The IAnimatable interface describes objects that are animated 
depending on the passed time. Any object that implements this interface
can be added to a juggler.

When an object should no longer be animated, it has to be removed from 
the juggler. To do this, you can manually remove it via the method 
juggler.remove(object), or the object can request to be removed by 
dispatching an event with the type Event.REMOVE_FROM_JUGGLER.

The "Tween" and the "DelayedCall" classes are an example of a class 
that dispatches such an event; you don't have to remove tweens or
delayedCalls manually from the juggler.
--]]

IAnimatable = class()

--Advance the time by a number of seconds.
function IAnimatable:advanceTime(deltaTime)
end
