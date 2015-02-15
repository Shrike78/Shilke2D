--[[---
Original code by Sirmabus - April 23, 2012

Fast implementation of assert that uses a printf-style 
message formatting and does not generate the message unless it is used
Also added some enhancements like pointing back to the actual assert line number,
and a fall through in case the assertion msg arguments are wrong (using a "pcall()").

The assert is evaluated only if __DEBUG_ASSERT__ is true (evaluated in Shilke2D include).

Inlcuding this module force the automatic replacement of assert with fast_assert.
The standard assert implementation is remapped on std_assert
--]]

---
-- Faster assert replacement that accept a printf-style message formatting
-- @function assert
-- @param condition a logical condition to verify
-- @param ... message string and optional arguments
function fast_assert(condition, ...)
	if __DEBUG_ASSERT__ and not condition then
		if next({...}) then
			local s,r = pcall(function (...) return(string.format(...)) end, ...)
			if s then
				error("assertion failed!: " .. r, 2)
			end
		end
		error("assertion failed!", 2)
	end
end

---
-- builtin assert function remapped
-- @function std_assert
-- @param condition a logical condition to verify
-- @tparam string message optional error message
std_assert = assert
assert = fast_assert
