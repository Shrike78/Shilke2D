--[[---
EventDispatcher is the base class for all classes that dispatch events. 
This is the Shilke2D version of the Flash class with the same name. 
Objects can communicate with each other through events. 

Compared the the Flash event system, Shilke2D's event system 
was highly simplified. They are simply dispatched to the target. 
As in the conventional Flash classes, display objects inherit
from EventDispatcher and can thus dispatch events. 

It's possible to register a function or a method as event listenr 
of a specific event type for an object that derived from EventDispatcher
--]]

EventDispatcher = class()

local Pending = {ADD = 0, REMOVE = 1, REMOVE_ALL = 2}

function EventDispatcher:init()
	--[[
	Stores all the registered listeners for all the events.
	The table is used as dictionary for event type. For each
	event type a table is used at the same time as array and as 
	a function map. The array part is used to make calls sorted 
	by registering order, the map to store functions. 
	Array stores map keys that can be either functions or objects,
	depending on registration logic
	--]]
	self.listeners = {}
	
	self.dispatching = false
	self.pendingList = {}
end


--[[---
It remove all the event listeners.
--]]
function EventDispatcher:dispose()
	self:removeEventListeners()
end

--[[---
Register a function as listener of a certain type of event.
It's not possible to register twice the same function as listener of the same event type
@function EventDispatcher:addEventListener
@param eventType the type of event for which the listener is registering
@param listenerFunc function registered as listener
--]]

--[[---
Register an obj method as listener of a certain type of event.
It's not possible to register twice the same object as listener of the same event type
@param eventType the type of event for which the listener is registering
@param listenerFunc the method registered as listener
@param listenerObj the obj registered as listener
--]]
function EventDispatcher:addEventListener(eventType, listenerFunc, listenerObj)
	
	if self.dispatching then
		table.insert(self.pendingList, {Pending.ADD, eventType, listenerFunc, listenerObj})
		return
	end
    
	if not self.listeners[eventType] then
		self.listeners[eventType] = {}
	end
	--if registering a method listenerObj is defined, else is nil
	local key = listenerObj or listenerFunc
	local listeners = self.listeners[eventType]

	if not listeners[key] then
		listeners[#listeners+1] = key
		listeners[key] = listenerFunc
	end
end

--[[---
Deregister a function as listener of a certain type of event.
@function EventDispatcher:removeEventListener
@param eventType the type of event for which the stop listening
@param listenerFunc function registered as listener
--]]

--[[---
Deregister a method as listener of a certain type of event.
@param eventType the type of event for which the stop listening
@param listenerFunc the method registered as listener
@param listenerObj the obj registered as listener
--]]
function EventDispatcher:removeEventListener(eventType, listenerFunc, listenerObj)
	if self.dispatching then
		table.insert(self.pendingList, {Pending.REMOVE, eventType, listenerFunc, listenerObj})
		return
	end

	if not self.listeners[eventType] then
		return
	end
	--if unregistering a method listenerObj is defined, else is nil
	local key = listenerObj or listenerFunc	
	local listeners = self.listeners[eventType]
	
	if listeners[key] then
		table.removeObj(listeners,key)
		listeners[key] = nil
	end	
end



--[[---
Removes all the listeners for a specific event
@param[opt=nil] eventType the type of Event for which we want to deregister all the listeners.
If no eventType is provided it removes all the listeners for all the events
--]]
function EventDispatcher:removeEventListeners(eventType)

	if self.dispatching then
		if eventType then 
			--remove all the pending operation related to the same eventType
			for i = #self.pendingList, 1, -1 do
				--check if the pending operation is related to the same eventType
				if self.pendingList[i][2] == eventType then
					table.remove(self.pendingList, i)
				end
			end
			table.insert(self.pendingList, {Pending.REMOVE_ALL, eventType})
		else
			table.clear(self.pendingList)
			table.insert(self.pendingList, {Pending.REMOVE_ALL})
		end
		return
	end

	if eventType then
		if self.listeners[eventType] then
			table.clear(self.listeners[eventType])
		end
	else
		for _,v in pairs(self.listeners) do
			table.clear(v)
		end
		table.clear(self.listeners)
	end
end

--[[---
Check if there's at least one eventListener for a specific type of event
@param eventType 
@return bool
--]]
function EventDispatcher:hasEventListener(eventType)
	return self.listeners[eventType] and #self.listeners[eventType]>0
end

--[[---
Dispatch an event to all the registered listeners. 
While dispatching, the lists of listener could be modified by 
actions of a listener callback, so to avoid problem in this 
phase add and remove operation are queued in a specific list
and then apply in the same order that were requested.
@param event the event that will be dispatch
--]]
function EventDispatcher:dispatchEvent(event)
	
	local listeners = self.listeners[event.type]
	--if there's no listener for this event just return
	if not listeners then
		return
	end
	
	--Set itself as sender of the event
	event.sender = self
	self.dispatching = true
	for _,k in ipairs(listeners) do
		--check if the listener is a simple function or a method
		if type(k) == 'function' then
			listeners[k](event)
		else
			listeners[k](k,event)
		end
	end
	self.dispatching = false
	
	--if listeners have been added or removed while dispatching, handle the queue of
	--pending operations
	if #self.pendingList > 0 then
		for _,v in ipairs(self.pendingList) do
			local action, eventType, func, obj = unpack(v)		
			if action == Pending.ADD then
				self:addEventListener(eventType, func, obj)
			elseif action == Pending.REMOVE then
				self:removeEventListener(eventType, func, obj)
			elseif action == Pending.REMOVE_ALL then
				self:removeEventListeners(eventType)
			else
				error("illegal operation: " .. action)
			end
		end
		table.clear(self.pendingList)
	end
end

--[[---
Dispatches an event to all the registered listeners. 
This method can be used only to dispatch base events and 
it's optimized because it uses a pool of event
@param eventType the type of the event that will be dispatched
--]]
function EventDispatcher:dispatchEventByType(eventType)
	--if there's no listener for this type just return
	if self.listeners[eventType] then 
		local e = ObjectPool.getObj(Event)
		e.type = eventType
		self:dispatchEvent(e)
		ObjectPool.recycleObj(e)
	end
end
