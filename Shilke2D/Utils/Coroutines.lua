-- Coroutines helper

function coroutine.sleep(time)
	local t0 = MOAISim.getElapsedTime()
	local t = 0
	while t < time do
		coroutine.yield()
		local t1 = MOAISim.getElapsedTime()
		local dt = t1-t0
		t0=t1
		t = t + dt
	end
end
