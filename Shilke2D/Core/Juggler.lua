--[[---
A Juggler animates objects implementing IAnimatable interface. 

A juggler is a simple object. It does no more than 
saving a list of objects implementing "IAnimatable" and advancing 
their time if it is told to do so (by calling its own "advanceTime"
method). When an animation is completed, it throws it away. 

You can create juggler objects yourself, just as well. That way, 
you can group your game into logical components that handle their
animations independently. All you have to do is call the "advanceTime"
method on your custom juggler once per frame.

Moreover the Juggler implements itself the IAnimatable interface, 
so a Juggler can be add to another Juggler. 
--]]

Juggler = class(nil,IAnimatable)

---Used internally to handle pending operation scheduled while "playing"
local Pending = {ADD = 0, REMOVE = 1, REMOVE_ALL = 2}

function Juggler:init()
	self.animatedObjs = {}
	self.pendingList ={}
	self.playing = false
	self.paused = false
end

function Juggler:dispose()
	self:clear()
end

--[[---
Used to pause the current juggler execution.
When a juggler is paused also the execution of all the managed IAnimatable objects is paused
@param paused true/false to enable/disable the pause status
@return nil
--]]
function Juggler:setPause(paused)
	self.paused = paused
end

--[[---
Return the current juggler pause state.
@return bool if the juggler is currently in pause
--]]
function Juggler:isPaused()
	return self.paused
end

--[[---
Advances the time of all the objects added to the juggler.
After the animation phase is done, it checks for queued add/remove 
operations and executes them in the same request order.
@param deltaTime millisec elapsed since last call
--]]
function Juggler:advanceTime(deltaTime)
	if self.paused then
		return
	end

	self.playing = true
	for _,obj in ipairs(self.animatedObjs) do
		obj:advanceTime(deltaTime)
	end
	self.playing = false

	if #self.pendingList > 0 then
		for _,v in ipairs(self.pendingList) do
			local action, obj = unpack(v)
			if action == Pending.ADD then
				self:add(obj)
			elseif action == Pending.REMOVE then
				self:remove(obj)
			elseif action == Pending.REMOVE_ALL then
				self:clear()
			else
				error("illegal operation: " .. action)
			end
		end
		table.clear(self.pendingList)
	end
end

--[[---
Internal function.
Called when a listened obj dispatch an Event.REMOVE_FROM_JUGGLER event
--]]
function Juggler:onRemoveEvent(event)
    self:remove(event.sender)
end

--[[---
Add an IAnimatable object to the juggler.
If the juggler is playing (in advanceTime) the add is queued, if not
the obj is added immediatly. If it's an eventDispatcher, the 
juggler register itself as a listener for the REMOVE_FROM_JUGGLER
@param obj An object that implement the IAnimatable interface
--]]
function Juggler:add(obj)
	
	if self.playing then 
		table.insert(self.pendingList, {Pending.ADD, obj})
		return
	end

	if table.find(self.animatedObjs,obj) == 0 then
		table.insert(self.animatedObjs,obj)
		if obj:is_a(EventDispatcher) then
			obj:addEventListener(Event.REMOVE_FROM_JUGGLER, Juggler.onRemoveEvent,self)
		end
	end
end

--[[---
Remove an object from the juggler.
If the juggler is playing (in advanceTime) the remove is queued, 
if not the obj is removed immediatly. If it's an eventDispatcher, 
the juggler deregister itself as listener for the REMOVE_FROM_JUGGLER
--]]
function Juggler:remove(obj)
	
	if self.playing then
		table.insert(self.pendingList, {Pending.REMOVE, obj})
		return
	end
		
	if table.removeObj(self.animatedObjs,obj) then
		if obj:is_a(EventDispatcher) then
			obj:removeEventListener(Event.REMOVE_FROM_JUGGLER, Juggler.onRemoveEvent,self)
		end
	end
end

--[[---
Remove all the objects from the juggler.
If the juggler is playing (advaceTime) the removal of the objects will take place during the next frame
--]]
function Juggler:clear()
	
	if self.playing then
		--remove all the other pending operations because of the remove_all call
		table.clear(self.pendingList)
		table.insert(self.pendingList, {Pending.REMOVE_ALL})
		return
	end
	
	for _,obj in ipairs(self.animatedObjs) do
		if obj:is_a(EventDispatcher) then
			obj:removeEventListener(Event.REMOVE_FROM_JUGGLER, Juggler.onRemoveEvent,self)
		end
	end
	table.clear(self.animatedObjs)

end
