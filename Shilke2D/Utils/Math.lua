-- math extende functions

-- than .5, the argument is rounded to the next lower integer.
function math.round(num) 
    return math.floor(num+.5)
end


function math.clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function math.clampAbs(x, maxAbs)
    return math.clamp(x, -maxAbs, maxAbs)
end


function math.clampLen(vec, maxLen)
    return vec:normalize() * math.min(vec:len(), maxLen)
end

function math.sign(x)
    if x < 0 then
        return -1
    elseif x > 0 then
        return 1
    else
        return x
    end
end

local eps = 1e-11

function math.fequals(x1,x2,dist)
	local dist = dist or eps
	return math.abs(x1-x2) <= dist and true or false
end
