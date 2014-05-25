--[[---
A DisplayObj position and transformation in space is defined by 3 vec2 and a scalar value:
-pivot
-position
-rotation
-scale

DisplayObjTransform is a class containing all this values and can be used to define in a compact way the 
position/transformation of a generic DisplayObj.

It's possible to make operation over a DisplayObjTransform object, in order to allow tweening animations.

Internally a set of 7 scalar is used to keep all infos instead of 3 vec2 and a scalar. That's to avoid or 
at least reduce memory and performance issues
--]]

DisplayObjTransform = class()

--[[---
Constructor. pivot, position, rotation and scale infos must be provided. It can be either in the
scalar form of px,py,x,y,r,sx,sy or in a vectorial (vec2) form like pivot, position, rotation, scale 
(where rotation is always a single scalar value)
Default values are zeroes for all components but scale (x,y) that defaults to 1.
--]]
function DisplayObjTransform:init(...)
	local args = {...}
	local numArgs = #args
	--no params -> use default values
	if numArgs == 0 then
		self.px, self.py, self.x, self.y, self.r, self.sx, self.sy = 0, 0, 0, 0, 0, 1, 1
	--first param is a number -> all params are number or default values
	elseif class_type(args[1]) == "number" then
		self.px = args[1]
		self.py = args[2] or 0
		self.x = args[3] or 0
		self.y = args[4] or 0
		self.r = args[5] or 0
		self.sx = args[6] ~= nil and args[6] or 1
		self.sy = args[7] ~= nil and args[7] or 1
	--first param is a vec2 -> all params are vec2 or default values
	else
		self.px, self.py = args[1]:unpack()
		self.x = args[2] and args[2].x or 0
		self.y = args[2] and args[2].y or 0
		self.r = args[3] or 0
		self.sx = args[4] and args[4].x or 1
		self.sy = args[4] and args[4].y or 1
	end
end


--[[---
copies components from given DisplayObjTransform
@param c the object to be copied
--]]
function DisplayObjTransform:copy(c)
	self.px = c.px
	self.py = c.py
	self.x = c.x
	self.y = c.y
	self.r = c.r
	self.sx = c.sx
	self.sy = c.sy
end

--[[---
returns a new DisplayObjTransform with the same values
@return DisplayObjTransform
--]]
function DisplayObjTransform:clone()
	local c = DisplayObjTransform(
		self.px, self.py,
		self.x, self.y,
		self.r,
		self.sx, self.sy
	)
	return c
end

---get pivot
--@return px
--@return py
function DisplayObjTransform:getPivot()
	return self.px, self.py
end

---set pivot
--@param px
--@param py
function DisplayObjTransform:setPivot(px,py)
	self.px, self.py = px, py
end

---get position
--@return x
--@return y
function DisplayObjTransform:getPosition()
	return self.x, self.y
end

---set position
--@param x
--@param y
function DisplayObjTransform:setPosition(x,y)
	self.x, self.y = x,y
end

---get rotation
--@return r
function DisplayObjTransform:getRotation()
	return self.r
end

---set rotation
--@param r
function DisplayObjTransform:setRotation(r)
	self.r = r
end

---get scale
--@return sx
--@return sy
function DisplayObjTransform:getScale()
	return self.sx, self.sy
end

---set scale
--@param sx
--@param sy
function DisplayObjTransform:setScale(sx,sy)
	self.sx, self.sy = sx, sy
end

--[[---
sums component by component two DisplayObjTransform object
@param t1 DisplayObjTransform
@param t2 DisplayObjTransform
@return DisplayObjTransform
--]]
function DisplayObjTransform.__add(t1,t2)
	return DisplayObjTransform(
			t1.px + t2.px,
			t1.py + t2.py,
			t1.x + t2.x,
			t1.y + t2.y,
			t1.r + t2.r,
			t1.sx + t2.sx,
			t1.sy + t2.sy
		)
end


--[[---
subtracts component by component two DisplayObjTransform object
@param t1 DisplayObjTransform
@param t2 DisplayObjTransform
@return DisplayObjTransform
--]]
function DisplayObjTransform.__sub(t1,t2)
	return DisplayObjTransform(
			t1.px - t2.px,
			t1.py - t2.py,
			t1.x - t2.x,
			t1.y - t2.y,
			t1.r - t2.r,
			t1.sx - t2.sx,
			t1.sy - t2.sy
		)
end


--[[---
Multiplies each component of a DisplayObjTransform by a scalar value. 
One of the params must be a number.
@param t1 DisplayObjTransform or a number
@param t2 DisplayObjTransform or a number
@return DisplayObjTransform
--]]
function DisplayObjTransform.__mul(t1,t2)
	if type(t1) == "number" then
		return DisplayObjTransform(
				t1 * t2.px,
				t1 * t2.py,
				t1 * t2.x,
				t1 * t2.y,
				t1 * t2.r,
				t1 * t2.sx,
				t1 * t2.sy
			)
	elseif type(t2) == "number" then
		return DisplayObjTransform(
				t1.px * t2,
				t1.py * t2,
				t1.x * t2,
				t1.y * t2,
				t1.r * t2,
				t1.sx * t2,
				t1.sy * t2
			)
	else
		error("invalid operation on color")
	end
end


--[[---
Divides each component of a DisplayObjTransform by a scalar value. 
@param t DisplayObjTransform
@param d number
@return DisplayObjTransform
--]]
function DisplayObjTransform.__div(t,d)
	return DisplayObjTransform(
			t.px / d,
			t.py / d,
			t.x / d,
			t.y / d,
			t.r / d,
			t.sx / d,
			t.sy / d
		)
end

---the == operation
function DisplayObjTransform.__eq(t1,t2)
	return t1.px == t2.px and t1.py == t2.py and
			t1.x == t2.x and t1.y == t2.y and t1.r  == t2.r and 
			t1.sx == t2.sx and t1.sy == t2.sy
end


--[[---
blend each component of two DisplayObjTransform by a given blend value
@param t1 DisplayObjTransform
@param t2 DisplayObjTransform
@param a number [0..1]
@return DisplayObjTransform t1*a + t2*(1-a)
--]]
function DisplayObjTransform.blend(t1, t2, a)
    return DisplayObjTransform(
			t1.px * a + t2.px * (1-a),
			t1.py * a + t2.py * (1-a),
			t1.x * a + t2.x * (1-a),
			t1.y * a + t2.y * (1-a),
			t1.r * a + t2.r * (1-a),
			t1.sx * a + t2.sx * (1-a),
			t1.sy * a + t2.sy * (1-a)
		)
end

--[[
---print each component value
function DisplayObjTransform:__tostring()
	local r = "pivot: (" .. self.px .. "," .. self.py .. ")"
	r = r .. "\nposition: " .. self.x .. "," .. self.y .. ")"
	r = r .. "\nrotation: " .. self.r
	r = r .. "\nscale: " .. self.sx .. "," .. self.sy .. ")"
	return r
end
--]]
