---Polygon class

---Find intersection between two lines
--@param start1 start point (vec2) of first line
--@param end1 end point (vec2) of first line
--@param start2 start point (vec2) of second line
--@param end2 end point (vec2) of second line
--@return vec2 if intersection exists or nil
function findLineIntersection(start1, end1, start2, end2)
	local x1,y1,x2,y2,x3,y3,x4,y4 = start1.x, start1.y, end1.x, end1.y, start2.x, start2.y, end2.x, end2.y
	local d = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
	if (d == 0) then return nil end

	local xi = ((x3-x4)*(x1*y2-y1*x2)-(x1-x2)*(x3*y4-y3*x4))/d
	local yi = ((y3-y4)*(x1*y2-y1*x2)-(y1-y2)*(x3*y4-y3*x4))/d
	
	if (xi < math.min(x1,x2) or xi > math.max(x1,x2)) then return nil end
	if (xi < math.min(x3,x4) or xi > math.max(x3,x4)) then return nil end
	return vec2(xi,yi)
end

Polygon = class()

---Helper function to convert a set of [x,y,..] to an array of vec2
--If needed add an extra point at the end to 'close' the polygon
local function toVec2(points)
	if #points == 0 then return nil end
	
	local res
	if type(points[1]) == 'number' then
		res = {}
		for i=1,#points/2 do
			res[#res+1] = vec2(points[2*i-1],points[2*i])
		end
	elseif class_type(points[1]) == vec2 then
		res = table.copy(points)
	end
	if res[1] ~= res[#res] then
		res[#res+1] = res[1]
	end
	return res
end

--[[---
Constructor
@usage
Polygon(x1,y1,x2,y2,...) - with x,y as numbers
Polygon(p1,p2,...) - with p as vec2
Polygon({x1,x2,...})
Polygon({p1,p2,...})
--]]
function Polygon:init(p,...)
	local points
	if class_type(p) == vec2 or type(p) == 'number' then
		points = {p,...}
	elseif type(p) == 'table' then
		points = p
	end
	self.points = toVec2(points)
	self._rect = Rect()
	self._invalidRect = true
end

---Calculates / Updates bounding rect of the polygon
function Polygon:updateRect()
	local xmin = math.huge
    local xmax = -math.huge
    local ymin = math.huge
    local ymax = -math.huge

    for i = 1, #self.points do
		local point = self.points[i]
        local x,y  = point.x,point.y
        xmin = math.min(xmin,x)
        xmax = math.max(xmax,x)
        ymin = math.min(ymin,y)
        ymax = math.max(ymax,y)
    end
    
    self._rect.x, self._rect.y = xmin, ymin
    self._rect.w, self._rect.h = (xmax-xmin), (ymax-ymin)
	self._invalidRect = false
end

--[[
function Polygon:insertPoint(v,idx)
	self._invalidRect = true
	if idx then
		table.insert(self.points,idx,v)
	else
		table.insert(self.points,v)
	end
end

function Polygon:removePoint(idx)
	self._invalidRect = true
	table.remove(self.points,idx)
end
--]]

---Returns an indexed point
--@param i index of the point to retrieve
--@return vec2 or nil if index out of bound
function Polygon:getPoint(i)
	return self.points[i]
end

---Returns an array of single x,y components
--@return x1,y1,x2,y2....
function Polygon:unpack()
	local res = {}
	for i=1,#self.points do
		res[#res+1] = self.points[i].x
		res[#res+1] = self.points[i].y
	end
	return unpack(res)
end

---Returns bounding rect of the polygon
--@param resultRect used to avoid the creation of a new rect. optional
--@return Rect
function Polygon:getRect(resultRect)
	if self._invalidRect then
		self:updateRect()
	end
    local r = resultRect or Rect()
    r:copy(self._rect)
    return r
end

---Checks if the polygon contains a given point
--@param x x coordinate of the point or a vec2 point
--@param y y coordinate of the point or nil
--@return bool
function Polygon:containsPoint(x,y)
	
	local y = y and y or x.y
	local x = y and x or x.x
	
	local polySides = #self.points - 1
	local j = polySides
	local res = false

	for i = 1, polySides do
		local p1 = self.points[i]
		local p2 = self.points[j]
		local x1,y1 = p1.x,p1.y
		local x2,y2 = p2.x,p2.y
		if (y1 < y and y2 >= y or y2 < y and y1 >= y) and
			(x1 <= x or x2 <= x) then
			if x1 + (y-y1)/(y2-y1)*(x2-x1)< x then
				res = not res
			end
		end
		j=i
	end
	return res
end

---Checks a given rect intersects the polygon
--@param p1 start point of the rect
--@param p2 end point of the rect
--@return bool
function Polygon:intersectSegment(p1,p2)
	for i = 1, #self.points-1 do
		if findLineIntersection(p1,p2,self.points[i],self.points[i+1]) then
			return true
		end
	end
	return false
end

---Checks intersection with another polygon
--@param poly the other polygon
--@return bool
function Polygon:intersectPolygon(poly)
	if not self:getRect():intersects(poly:getRect()) then
		return false
	end
	
	for i = 1, #self.points-1 do
		if poly:containsPoint(self.points[i].x,self.points[i].y) then
			return true
		end
	end
	
	for i = 1, #poly.points-1 do
		if self:containsPoint(poly.points[i].x,poly.points[i].y) then
			return true
		end
	end
	
	for i = 1, #self.points-1 do
		if poly:intersectSegment(self.points[i],self.points[i+1]) then
			return true
		end
	end
	return false
end

---Merges two polygons
--@param poly the polygon to be merged with this
--@return a new polygon obtained by the merge of the two. 
--nil if the two polygons do not intersect.
function Polygon:merge(poly)
	if not self:getRect():intersects(poly:getRect()) then
		return nil
	end
	
	local newPoly = {}
	
	function switch(current,other)
		local tmp = current
		current = other
		other = tmp
	end
	
	local current = self
	local other = poly
	local currId = nil
	
	for i = 1,2 do
		for i = 1, #current.points-1 do
			if not other:containsPoint(self.points[i].x,self.points[i].y) then
				currId = i
				break
			end
		end
		
		if not currId then
			if i == 1 then
				local tmp = current
				current = other
				other = tmp
			else 
				return nil
			end
		else
			break
		end
	end
	
	newPoly[#newPoly+1] = current.points[currId]
	--print(newPoly[#newPoly])
	local newP = current.points[currId]
	
	local eps = 1e-11
	
	while true do
		local intersect = {}
		for i = 1, #other.points-1 do
			local p = findLineIntersection(newP,current.points[currId+1],other.points[i],other.points[i+1])
			if p then
				if (math.abs(p.x - newP.x) > eps or math.abs(p.y - newP.y)> eps) then
					intersect[#intersect+1] = {p,i}
				end
			end
		end
		
		
		if #intersect == 0 then
			currId = currId+1
			newP = current.points[currId]
		else
			if #intersect == 1 then
				newP = intersect[1][1]
				currId = intersect[1][2]
			elseif #intersect > 1 then
				local d = (intersect[1][1] - current.points[currId]):len()
				newP = intersect[1][1]
				local tmpId = currId
				currId = intersect[1][2]
				for i = 2,#intersect do
					local d2 = (intersect[i][1] - current.points[tmpId]):len()
					if  d2 < d then
						d = d2
						newP = intersect[i][1]
						currId = intersect[i][2]
					end
				end
			end
			local tmp = current
			current = other
			other = tmp
		end
		
		if currId == #current.points then currId = 1 end
		newPoly[#newPoly+1] = newP
		--print(newP)
		if newP == newPoly[1] then
			break
		end
	end
	
	return Polygon(newPoly)
end
