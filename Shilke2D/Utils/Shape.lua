--[[---
Basic geometry classes with draw and intersection helpers.

Shape is an abstract base class, Circle and Rect are concrete classes
--]]

Shape = class()

function Shape:init()
end

---returns a clone of the current shape
function Shape:clone()
    return table.copy(self)
end

---abstract method
function Shape:copy(s)
    error("override me")
end

---abstract method
function Shape:containsPoint(x,y)
    error("override me")
end

---abstract intersection method between 2 shapes
function Shape:intersects(s2)
    error("override me")
end

---abstract draw method
function Shape:draw()
    error("override me")
end

---Checks intersection of two rectangles
--@param r1 Rect
--@param r2 Rect
--@return bool
local function int_rect2rect(r1,r2)
    if r1.x > (r2.x + r2.w) or (r1.x + r1.w) < r2.x then
        return false
    end
    if r1.y > (r2.y + r2.h) or (r1.y + r1.h) < r2.y then
        return false
    end
    return true
end

---Checks intersection of two circles
--@param c1 Circle
--@param c2 Circle
--@return bool
local function int_circle2circle(c1,c2)
    if (c1.r+c2.r)^2 < (c1.x-c2.x)^2 +(c1.y-c2.y)^2 then
        return false
    end
    return true
end

---Checks intersection of a rectangle and a circle
--@param r rect
--@param c Circle
--@return bool
local function int_rect2circle(r,c)
    local halfw = r.w/2
    local halfh = r.h/2
    
    local circleDist = vec2(math.abs(c.x-r.x-halfw),
        math.abs(c.y-r.y-halfh))
        
    if circleDist.x <= halfw then return true end
    if circleDist.y <= halfh then return true end
    if circleDist.x > (halfw + c.r) then return false end
    if circleDist.y > (halfh + c.r) then return false end
   
    local cornerDist_sq = (circleDist.x - halfw)^2 + 
        (circleDist.y - halfh)^2
    local r2 = c.r^2
    return cornerDist_sq <= r2
end

--Rect class
Rect = class(Shape)

---returns a string describing rect components
Rect.__tostring = function(r)
    return string.format("[x=%f, y=%f, w=%f, h=%f]",
                r.x,r.y,r.w,r.h)
end

---Constructor
--@param x default 0
--@param y default 0
--@param w default 0
--@param h default 0
function Rect:init(x,y,w,h)
    Shape.init(self)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 0
    self.h = h or 0
end


--[[---
assign rect values
@param x 
@param y 
@param w 
@param h 
@return Rect self 
--]]
function Rect:set(x,y,w,h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
	return self
end

---Updates itself copying another rect
--@param r the rect to be copied
--@return self
function Rect:copy(r)
    self.x = r.x
    self.y = r.y
    self.w = r.w
    self.h = r.h
	return self
end

---Returns the center of the rect
--@return x
--@return y
function Rect:getCenter()
    return self.x + self.w/2, self.y + self.h/2
end

---Checks if a point is inside the rect
--@param x
--@param y
--@return bool
function Rect:containsPoint(x,y)
    if x > self.x and y > self.y then
        if x < (self.x + self.w) and y < (self.y + self.h) then
            return true
        end
    end
    return false
end

---Checks intersection with other Shapes (rect or circle)
--@param s2 the other shape
--@return bool
function Rect:intersects(s2)
    if s2:is_a(Rect) then
        return int_rect2rect(self,s2)
    elseif s2:is_a(Circle) then
        return int_rect2circle(self,s2)
    end
end

---Returns the intersection area between two rects
--@tparam Rect r2 the second rect
--@tparam[opt=nil] Rect helperRect if provided is filled and used as return object
--@treturn Rect. if the intersection is nil it returns a defaul 
---Rect with each component at 0
function Rect:intersection(r2, helperRect)
	local res = nil
    if int_rect2rect(self,r2) then
		res = helperRect or Rect()
        res.x = math.max(r2.x,self.x)
        res.y = math.max(r2.y,self.y)
        local x2 = math.min(r2.x + r2.w,self.x + self.w)
        local y2 = math.min(r2.y + r2.h,self.y + self.h)
        res.w = x2 - res.x
        res.h = y2 - res.y
    end
    return  res
end

---Wraps the MOAIDraw.drawRect call
function Rect:draw()
    MOAIDraw.drawRect(self.x, self.y, self.x + self.w, self.y+self.h)
end

--Circle class
Circle = class(Shape)

---returns a string describing circle components
Circle.__tostring = function(c) 
    return string.format("[x=%f, y=%f, r=%f]",c.x,c.y,c.r)
end

---Constructor
--@param x center x of the circle
--@param y center y of the circle
--@param r radius of the circle
function Circle:init(x,y,r)
    self.x = x or 0
    self.y = y or 0
    self.r = r or 0
end

--[[---
assign circle values
@param x 
@param y 
@param r
@return Circle self 
--]]
function Circle:set(x,y,r)
    self.x = x
    self.y = y
    self.r = r
	return self
end

---Updates itself copying another circle
--@param c the circle to be copied
--@return self
function Circle:copy(c)
    self.x = c.x
    self.y = c.y
    self.r = c.r
	return self
end

---Checks if a point is inside the circle
--@param x
--@param y
--@return bool
function Circle:containsPoint(x,y)
    if x > (self.x - self.r) and x < (self.x + self.r) then
        if y > (self.y - self.r) and y < (self.y + self.r) then
            return true
        end
    end
    return false
end

---Checks intersection with other Shapes (rect or circle)
--@param s2 the other shape
--@return bool
function Circle:intersects(s2)
    if s2:is_a(Circle) then
        return int_circle2circle(self,s2)
    elseif s2:is_a(Rect) then
        return int_rect2circle(s2,self)
    end
end

---Wraps the MOAIDraw.drawCircle call
function Circle:draw()
	MOAIDraw.drawCircle(self.x, self.y, self.r)
end