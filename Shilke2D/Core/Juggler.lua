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
local Pending = {
	ADD = 0, 
	REMOVE = 1
}

function Juggler:init()
    self.animatedObjs = {}
    self.pendingList ={}
    self.playing = false
    self.paused = false
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
    for _,v in ipairs(self.animatedObjs) do
        v:advanceTime(deltaTime)
    end
    self.playing = false
    
    if #self.pendingList > 0 then
        for _,v in ipairs(self.pendingList) do
            if v.action == Pending.ADD then
                self:add(v.obj)
            elseif v.action == Pending.REMOVE then
                self:remove(v.obj)
            else
                error("illegal operation: "..v.action)
            end
        end
        table.clear(self.pendingList)
    end
end

--[[---
Add an IAnimatable object to the juggler.
If the juggler is playing (in advanceTime) the add is queued, if not
the obj is added immediatly. If it's an eventDispatcher, the 
juggler register itself as a listener for the REMOVE_FROM_JUGGLER
@param obj An object that implement the IAnimatable interface
--]]
function Juggler:add(obj)
    --assert(obj:implements(IAnimatable), debug.getinfo(1,"n").name .. 
    --    " obj doesn't implement IAnimatable")
        
    if self.playing then 
        table.insert(self.pendingList,{
            action = Pending.ADD,
            obj = obj
        })
        return
    end
    
	if table.find(self.animatedObjs,obj) == 0 then
		table.insert(self.animatedObjs,obj)
		if obj:is_a(EventDispatcher) then
			obj:addEventListener(Event.REMOVE_FROM_JUGGLER,
				Juggler.onRemoveEvent,self)
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
        table.insert(self.pendingList,{
            action = Pending.REMOVE,
            obj = obj
        })
        return
    end
        
    if table.removeObj(self.animatedObjs,obj) then
		if obj:is_a(EventDispatcher) then
			obj:removeEventListener(Event.REMOVE_FROM_JUGGLER,
				Juggler.onRemoveEvent,self)
		end
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
Remove all the objects from the juggler.
If the juggler is playing (advaceTime) the removal of the objects will take place during the next frame
--]]
function Juggler:clear()
	--stop all the pending add operation
	for i = #self.pendingList,1,-1 do
		local a = self.pendingList[i]
		if a.action == Pending.ADD then
			self.pendingList[i] = nil
		end
	end
	--request for remove all the other objects
	for _,v in ipairs(self.animatedObjs) do
		self:remove(v)
	end
	-- the real clear will be done at next frame, whene all the 'pending remove' will be completed
end
