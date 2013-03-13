-- Geometry

Shape = class()

function Shape:init()
end

function Shape:clone()
    return table.copy(self)
end

function Shape:copy(s)
    error("override me")
end

function Shape:containsPoint(x,y)
    error("override me")
end

function Shape:intersects(s2)
    error("override me")
end

function Shape:draw()
    error("override me")
end

local function int_rect2rect(r1,r2)
    if r1.x > (r2.x + r2.w) or (r1.x + r1.w) < r2.x then
        return false
    end
    if r1.y > (r2.y + r2.h) or (r1.y + r1.h) < r2.y then
        return false
    end
    return true
end

local function int_circle2circle(c1,c2)
    if (c1.r+c2.r)^2 < (c1.x-c2.x)^2 +(c1.y-c2.y)^2 then
        return false
    end
    return true
end

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

-- Rect 

Rect = class(Shape)

Rect.__tostring = function(r)
    return string.format("[x=%f, y=%f, w=%f, h=%f]",
                r.x,r.y,r.w,r.h)
end

function Rect:init(x,y,w,h)
    Shape.init(self)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 0
    self.h = h or 0
end

function Rect:copy(r)
    self.x = r.x
    self.y = r.y
    self.w = r.w
    self.h = r.h
end

function Rect:getCenter()
    return self.x + self.w/2, self.y + self.h/2
end

function Rect:containsPoint(x,y)
    if x > self.x and y > self.y then
        if x < (self.x + self.w) and y < (self.y + self.h) then
            return true
        end
    end
    return false
end

-- intersection is meant with rect 0,0 in bottom left position
function Rect:intersects(s2)
    if s2:is_a(Rect) then
        return int_rect2rect(self,s2)
    elseif s2:is_a(Circle) then
        return int_rect2circle(self,s2)
    end
end

function Rect:intersection(r2)
    res = Rect()
    if int_rect2rect(self,r2) then
        res.x = math.max(r2.x,self.x)
        res.y = math.max(r2.y,self.y)
        local x2 = math.min(r2.x + r2.w,self.x + self.w)
        local y2 = math.min(r2.y + r2.h,self.y + self.h)
        res.w = x2 - res.x
        res.h = y2 - res.y
    end
    return  res
end

function Rect:draw()
    rect(self.x, self.y, self.w, self.h)
end

-- Circle

Circle = class(Shape)

Circle.__tostring = function(c) 
    return string.format("[x=%f, y=%f, r=%f]",c.x,c.y,c.r)
end

function Circle:init(x,y,r)
    self.x = x or 0
    self.y = y or 0
    self.r = r or 0
end

function Circle:copy(c)
    self.x = c.x
    self.y = c.y
    self.r = c.r
end

function Circle:containsPoint(x,y)
    if x > (self.x - self.r) and x < (self.x + self.r) then
        if y > (self.y - self.r) and y < (self.y + self.r) then
            return true
        end
    end
    return false
end

function Circle:intersects(s2)
    if s2:is_a(Circle) then
        return int_circle2circle(self,s2)
    elseif s2:is_a(Rect) then
        return int_rect2circle(s2,self)
    end
end

function Circle:draw()
    ellipse(self.x, self.y, self.r*2)
end