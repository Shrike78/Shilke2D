 --[[---
Color class.
- Wraps r,g,b,a floating number. There is no real assumption about the range value, they can be 
also negative
- the unpak_normalized() call is the only call that assumes values in the range of [0,255] and that
returns a value divided by 255, so normalized in MOAI [0,1] color space
--]]
Color = class()

---Constructor.
--if a param is not provided defaul value is 255
function Color:init(r,g,b,a)
	self.r = r or 255
	self.g = g or 255
	self.b = b or 255
	self.a = a or 255
end

---Returns the 4 components
--@return r
--@return g
--@return b
--@return a
function Color:unpack()
	return self.r,self.g,self.b,self.a
end
	
---Returns the 4 components normalized (it assumes values in range [0,255]
--@return r/255
--@return g/255
--@return b/255
--@return a/255
function Color:unpack_normalized()
	return math.clamp(self.r,0,255)/255,
			math.clamp(self.g,0,255)/255,
			math.clamp(self.b,0,255)/255,
			math.clamp(self.a,0,255)/255
end

---sum two color
function Color.__add(c1,c2)
	return Color(
			c1.r + c2.r,
			c1.g + c2.g,
			c1.b + c2.b,
			c1.a
		)
end

---subtract two color
function Color.__sub(c1,c2)
	return Color(
			c1.r - c2.r,
			c1.g - c2.g,
			c1.b - c2.b,
			c1.a
		)
end

---multiply a color by a number
function Color.__mul(c1,c2)
	if type(c1) == "number" then
		return Color(
			c1 * c2.r, 
			c1 * c2.g,
			c1 * c2.b,
			c2.a
		)
	elseif type(c2) == "number" then
		return Color(
			c2 * c1.r,
			c2 * c1.g,
			c2 * c1.b,
			c1.a
		)
	else
		error("invalid operation on color")
	end
end

---divide a color by a number
function Color.__div(c,d)
	return Color(
		c.r/d, 
		c.g/d,
		c.b/d,
		c.a
	)
end

---print color components value
function Color:__tostring()
	return "("..self.r..","..self.g..","..self.b..","..self.a..")"
end

---blend 2 colors, taking the alpha of the first color
function Color.blend(c1, c2, a)
    return Color(c1.r * a + c2.r * (1-a),
                 c1.g * a + c2.g * (1-a),
                 c1.b * a + c2.b * (1-a),
                 c1.a
                )
end

---color space conversion
function Color.hsv2rgb(h, s, v)
	local floor = math.floor

    -- h, s, v is allowed having values between [0 ... 1].

    h = 6 * h
    local i = floor(h - 0.000001)
    local f = h - i
    local m = v*(1-s)
    local n = v*(1-s*f)
    local k = v*(1-s*(1-f))
    local r,g,b
    
    if i<=0 then
        r = v; g = k; b = m
    elseif i==1 then
        r = n; g = v; b = m
    elseif i==2 then
        r = m; g = v; b = k
    elseif i==3 then
        r = m; g = n; b = v
    elseif i==4 then
        r = k; g = m; b = v
    elseif i==5 then
        r = v; g = m; b = n
    end
    return floor(r*255), floor(g*255), floor(b*255)
end

