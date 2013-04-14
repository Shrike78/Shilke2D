--[[---
PerformanceTimer is an helper class that implements an high res timer
that returns time in millisec since initialization and that can be used also as stopwatch.
It's based on socket.gettime() call
--]]

require 'socket'

PerformanceTimer = class()

function PerformanceTimer:init()
	self.t0 = socket.gettime()*1000
	self.t1 = self.t0
end

---Returns time elapsed since initialization of the object
--@return millisec
function PerformanceTimer:getTime()
	return (socket.gettime()*1000 - self.t0)
end

---Returns time elapsed since last getDeltaTime() call or since 
--initialization (first call)
--@return millisec
function PerformanceTimer:getDeltaTime()
	local t = socket.gettime()*1000
	local r = t-self.t1
	self.t1 = t
	return r
end
