---Extends math namespace

---Rounds a number.
--@param num the number to round
--@return number rounded to nearest int value
function math.round(num) 
    return math.floor(num+.5)
end

---Clamps a number between a min and a max value
function math.clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

---Clamps a number between a value and its negative
function math.clampAbs(x, maxAbs)
    return math.clamp(x, -maxAbs, maxAbs)
end


---Clamps a vec2 to a maximum length value
function math.clampLen(vec, maxLen)
    return vec:normalize() * math.min(vec:len(), maxLen)
end

---Returns the sign of a number. 0 if the number is 0
function math.sign(x)
    if x < 0 then
        return -1
    elseif x > 0 then
        return 1
    else
        return x
    end
end

---epsilon = 1e-11
local eps = 1e-11

--[[---
Checks if 2 numbers are equals "enough".
Because for floating point numbers the equals operator raises problems,
it's possible to use this function the check if the difference bewteen 2 
number is as small as desired.
@param x1 first number
@param x2 second number
@param dist maximum distance allowed to consider the 2 number equals. default value is eps
@return bool
--]]
function math.fequals(x1,x2,dist)
	local dist = dist or eps
	return math.abs(x1-x2) <= dist and true or false
end
