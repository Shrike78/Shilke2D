--[[---

vec2 class.

Copyright (c) 2010 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local sqrt, cos, sin = math.sqrt, math.cos, math.sin

vec2 = class()

---Constructor
--@param x default 0
--@param y default 0
function vec2:init(x,y)
	self.x = x or 0
	self.y = y or 0
end

---Returns a copy of self, with x,y also cloned from self
function vec2:clone()
	return vec2(self.x, self.y)
end

---Returns unpacked values
--@return x
--@return y
function vec2:unpack()
	return self.x, self.y
end

---Prints components value
function vec2:__tostring()
	return "("..tonumber(self.x)..","..tonumber(self.y)..")"
end

---the unary - operation.
function vec2.__unm(a)
	return vec2(-a.x, -a.y)
end

---Sum operator between vec2
function vec2.__add(a,b)
	return vec2(a.x+b.x, a.y+b.y)
end

---Subtraction operator between vec2
function vec2.__sub(a,b)
	return vec2(a.x-b.x, a.y-b.y)
end

---Multiply a vec2 by a number or by another vec2
function vec2.__mul(a,b)
	if type(a) == "number" then
		return vec2(a*b.x, a*b.y)
	elseif type(b) == "number" then
		return vec2(b*a.x, b*a.y)
	else
		return a.x*b.x + a.y*b.y
	end
end

---Divides a vec2 by a number
function vec2.__div(a,b)
	return vec2(a.x / b, a.y / b)
end

---the == operation
function vec2.__eq(a,b)
	return a.x == b.x and a.y == b.y
end

---the < operation
function vec2.__lt(a,b)
	return a.x < b.x or (a.x == b.x and a.y < b.y)
end

---the <= operation
function vec2.__le(a,b)
	return a.x <= b.x and a.y <= b.y
end

---Multiplies vectors component per component
function vec2.permul(a,b)
	return vec2(a.x*b.x, a.y*b.y)
end

---Calculates len^2
function vec2:lenSqr()
	return self.x * self.x + self.y * self.y
end

---Calculates len
function vec2:len()
	return sqrt(self:lenSqr())
end

---Calculates distance between 2 points
function vec2.dist(a, b)
	return (b-a):len()
end

---Normalizes the vector
--@return self
function vec2:normalize_inplace()
	local l = self:len()
	self.x, self.y = self.x / l, self.y / l
	return self
end

---Returns a normalized vector
--@return vec2
function vec2:normalized()
	return self / self:len()
end

---Returns a normalized vector
--@return vec2
function vec2:normalize()
	return self / self:len()
end

---Rotates the vector of phi radians
--@param phi radians
--@return self
function vec2:rotate_inplace(phi)
	local c, s = cos(phi), sin(phi)
	self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
	return self
end

---Returns a rotated vector
--@param phi radians
--@return vec2
function vec2:rotated(phi)
	return self:clone():rotate_inplace(phi)
end

---Returns a rotated vector
--@param phi radians
--@return vec2
function vec2:rotate(phi)
	return self:clone():rotate_inplace(phi)
end

function vec2:perpendicular()
	return vec2(-self.y, self.x)
end

---Returns the projection of the vector on another vector
--@param v vec2 on which to project the vector
--@return vec2
function vec2:projectOn(v)
	return (self * v) * v / v:lenSqr()
end

function vec2:project(unit)
    return self:dot(unit)
end

function vec2:mirrorOn(other)
	return 2 * self:projectOn(other) - self
end

---Cross product of two vectors
--@return vec2
function vec2:cross(other)
	return self.x * other.y - self.y * other.x
end

---Dot product of two vectors
--@return vec2
function vec2:dot(other)
	return self.x * other.x + self.y * other.y
end

---Returns the angle between two vectors
--@return radians
function vec2:angleBetween(other)
	local alpha1 = math.atan2(self.y, self.x)
	local alpha2 = math.atan2(other.y, other.x)
	return alpha2 - alpha1
end
