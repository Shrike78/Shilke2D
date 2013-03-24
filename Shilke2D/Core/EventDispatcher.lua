--[[---
EventDispatcher is the base class for all classes that dispatch events. 
This is the Shilke2D version of the Flash class with the same name. 
Objects can communicate with each other through events. 

Compared the the Flash event system, Shilke2D's event system 
was highly simplified. They are simply dispatched at the target. 
As in the conventional Flash classes, display objects inherit
from EventDispatcher and can thus dispatch events. 

It's possible to register a function or a method as event listenr 
of a specific event type for an object that derived from EventDispatcher
--]]

EventDispatcher = class()

local Pending = {ADD = 0, REMOVE = 1, REMOVE_ALL = 2}

function EventDispatcher:init()
    --use 2 list with different index logic to store
    --functions event listener and methods event listener
    self.eventListenersFunc = {}
    self.eventListenersMethods = {}
    self.dispatching = false
    self.pendingList = {}
end

--create a single event shared between every EventDispatcher, to avoid fragmentation
local __event_remove_from_juggler = Event(Event.REMOVE_FROM_JUGGLER)

--[[---
First it dispatches a REMOVE_FROM_JUGGLER event to be safely detatched by jugglers. 
Then it remove all the event listeners.
--]]
function EventDispatcher:dispose()
	self:dispatchEvent(__event_remove_from_juggler)
	self:removeEventListeners()
end

--[[---
Register a function or a method as listener of a certain type of event.
@param eventType the type of event for which the listener is registering
@param listenerFunc function registered as callback for the event
@param listenerObj if provided, listenerFunc is considered as a method of listenerObj. 
If nil listenerFunc is considered as a function
--]]
function EventDispatcher:addEventListener(eventType, listenerFunc, 
		listenerObj)
        
    if self.dispatching then
        table.insert(self.pendingList,{
            action = Pending.ADD, 
            eventType = eventType, 
            listenerFunc = listenerFunc, 
            listenerObj = listenerObj
        })
        return
    end
    
    if not listenerObj then
        if not self.eventListenersFunc[eventType] then
            self.eventListenersFunc[eventType] = {}
        end
        table.insert(self.eventListenersFunc[eventType], listenerFunc)
    else
        if not self.eventListenersMethods[eventType] then
            self.eventListenersMethods[eventType] = {}
        end
        self.eventListenersMethods[eventType][listenerObj] = listenerFunc
    end
end

--[[---
Deregister a function or a method as listener of a certain type of event.
@param eventType the type of event for which the stop listening
@param listenerFunc function registered as callback for the event
@param listenerObj if provided, listenerFunc is considered as a method of listenerObj. 
If nil listenerFunc is considered as a function
--]]
function EventDispatcher:removeEventListener(eventType, listenerFunc, 
		listenerObj)
    
    if self.dispatching then
        table.insert(self.pendingList,{
            action = Pending.REMOVE, 
            eventType = eventType, 
            listenerFunc = listenerFunc, 
            listenerObj = listenerObj
        })
        return
    end
    
    if not listenerObj then
        local obj = table.removeObj(self.eventListenersFunc[eventType], 
            listenerFunc)
            --assert(obj,
            --    "listenerFunc not registered to this eventDispatcher")
    else
        --assert(self.eventListenersMethods[eventType][listenerObj],
        --    "listenerMethod not registered to this eventDispatcher")
         self.eventListenersMethods[eventType][listenerObj] = nil
    end
end

--[[---
Remove all the listeners for a specific event
@param eventType the type of Event for which we want to deregister all the listeners.
If nil all the listeners of all types of events will be removed.
--]]
function EventDispatcher:removeEventListeners(eventType)
    if self.dispatching then
        table.insert(self.pendingList,{
            action = Pending.REMOVE_ALL, 
            eventType = eventType
        })
        return
    end
    
    if eventType then
        if self.eventListenersFunc[eventType] then
            table.clear(self.eventListenersFunc[eventType])
        end
        if self.eventListenersMethods[eventType] then
            table.clear(self.eventListenersMethods[eventType])
        end
    else
        for _,v in pairs(self.eventListenersFunc) do
            table.clear(v)
        end
        for _,v in pairs(self.eventListenersMethods) do
            table.clear(v)
        end
        table.clear(self.eventListenersFunc)
        table.clear(self.eventListenersMethods)
    end
end

--[[---
Check if there's at least one eventListener for a specific type of event
@param eventType 
@return bool
--]]
function EventDispatcher:hasEventListener(eventType)
    if self.eventListenersFunc[eventType] and 
        #self.eventListeners[eventType]>0 then
            return true
    elseif self.eventListenersMethods[eventType] then
        for _,_ in self.eventListenersMethods[eventType] do
            return true
        end
    end
    return false
end

--[[---
Dispatch an event to all the registered listeners. 
While dispatching, the lists of listener could be modified by 
actions of a listener callback, so to avoid problem in this 
phase add and remove operation are queued in a specific list
and then apply in the same order that were requested.
@param event the event that will be dispatch to all the registered listener 
for this type of event
--]]
function EventDispatcher:dispatchEvent(event)
    --Set itself as sender of the event
    event.sender = self
    self.dispatching = true
    if self.eventListenersFunc[event.type] then
        for _,func in ipairs(self.eventListenersFunc[event.type]) do
            func(event)
        end
    end
    if self.eventListenersMethods[event.type] then
        for obj,func in pairs(self.eventListenersMethods[event.type]) do
            func(obj,event)
        end
    end
    self.dispatching = false
    
    if #self.pendingList > 0 then
        for _,v in ipairs(self.pendingList) do
            if v.action == Pending.ADD then
                self:addEventListener(v.eventType,
                    v.listenerFunc,v.listenerObj)
            elseif v.action == Pending.REMOVE then
                self:removeEventListener(v.eventType,
                    v.listenerFunc,v.listenerObj)
            elseif v.action == Pending.REMOVE_ALL then
                self:removeEventListeners(v.eventType)
            else
                error("illegal operation: " .. v.action)
            end
        end
        table.clear(self.pendingList)
    end
end

