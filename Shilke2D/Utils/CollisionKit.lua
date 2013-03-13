-- CollisionKit

--[[
imageHitTest

check pixel perfect overlap of 2 images

parameters
    i1: image 1
    p1: top left position (vec2) of image1
    a1: alpha treshold to consider image1 pixel transparent
    i2: image 2
    p2: top left position (vec2) of image2
    a2: alpha treshold to consider image2 pixel transparent
--]]
function imageHitTest(i1,p1,a1,i2,p2,a2)
	
	local w1,h1 = i1:getSize()
	local w2,h2 = i2:getSize()

	--alpha values are [0,255]
	local a1 = a1/255
	local a2 = a2/255
    
    local r1 = Rect(p1.x,p1.y,w1,h1)
    local r2 = Rect(p2.x,p2.y,w2,h2)
    if not r1:intersects(r2) then 
        return false 
    end
    if p1.x <= p2.x then
        r1.x = p2.x - p1.x
        r2.x = 0
        r1.w = r1.w - r1.x
    else
        r1.x = 0
        r2.x = p1.x - p2.x
        r1.w = r2.w - r2.x
    end
    if p1.y <= p2.y then
        r1.y = p2.y - p1.y
        r2.y = 0
        r1.h = r1.h - r1.y
    else
        r1.y = 0
        r2.y = p1.y - p2.y
        r1.h = r2.h - r2.y
    end
	
	if r1.w == 0 or r1.h == 0 then return false end
	
	for i = 1,r1.w do
		for j = 1,r1.h do
			local _,_,_,a = i1:getRGBA(r1.x + i, r1.y + j)
			if a > a1 then
				_,_,_,a = i1:getRGBA(r2.x + i, r2.y + j)
				if a > a2 then
					return true
				end
			end
		end
	end
    return false
end

--[[
imageHitTestEx

check pixel perfect overlap of 2 images

parameters
    i1: image 1
    p1: top left position (vec2) of image1
    a1: alpha treshold to consider image1 pixel transparent
    i2: image 2
    p2: top left position (vec2) of image2
    a2: alpha treshold to consider image2 pixel transparent
	
	rect1: (optional) can define a sub region over image1 (position and size)
	rect2: (optional) can define a sub region over image2 (position and size)
	
	rot1: (optional) if true rect1 must be considered rotated 90* anticlock wise
	rot2 (optional) if true rect2 must be considered rotated 90* anticlock wise
--]]
function imageHitTestEx(i1,p1,a1,i2,p2,a2,rect1,rect2,rot1,rot2)
	
    local w1,h1,w2,h2,o1x,o1y,o2x,o2y
	
	if rect1 then
		w1,h1 = rect1.w, rect1.h
		o1x,o1y = rect1.x, rect1.y
    else
		w1,h1 = i1:getSize()
		o1x,o1y = 0,0
	end
	
	if rect2 then
		w2,h2 = rect2.w, rect2.h
		o2x,o2y = rect2.x, rect2.y
    else
		w2,h2 = i2:getSize()
		o2x,o2y = 0,0
	end

	if rot1 then
		w1,h1 = h1,w1
	end
	if rot2 then
		w2,h2 = h2,w2
	end
	
	--alpha values are [0,255]
	local a1 = a1/255
	local a2 = a2/255
    
    local r1 = Rect(p1.x,p1.y,w1,h1)
    local r2 = Rect(p2.x,p2.y,w2,h2)
    if not r1:intersects(r2) then 
        return false 
    end
    if p1.x <= p2.x then
        r1.x = p2.x - p1.x
        r2.x = 0
        r1.w = r1.w - r1.x
    else
        r1.x = 0
        r2.x = p1.x - p2.x
        r1.w = r2.w - r2.x
    end
    if p1.y <= p2.y then
        r1.y = p2.y - p1.y
        r2.y = 0
        r1.h = r1.h - r1.y
    else
        r1.y = 0
        r2.y = p1.y - p2.y
        r1.h = r2.h - r2.y
    end
	
	if r1.w == 0 or r1.h == 0 then return false end

	if not rot1 and not rot2 then
		local _x1,_y1 = (o1x + r1.x), (o1y + r1.y)
		local _x2,_y2 = (o2x + r2.x), (o2y + r2.y)
		for i = 1,r1.w do
			for j = 1,r1.h do
				local _,_,_,a = i1:getRGBA(_x1 + i, _y1 + j)
				if a > a1 then
					_,_,_,a = i1:getRGBA(_x2 + i, _y2 + j)
					if a > a2 then
						return true
					end
				end
			end
		end
	elseif not rot1 and rot2 then
		local _x1,_y1 = (o1x + r1.x), (o1y + r1.y)
		local _x2,_y2 = (o2x + h2 - r2.y), (o2y + r2.x)
		for i = 1,r1.w do
			for j = 1,r1.h do
				local _,_,_,a = i1:getRGBA(_x1 + i, _y1 + j)
				if a > a1 then
					_,_,_,a = i2:getRGBA(_x2 - j, _y2 + i)
					if a > a2 then
						return true
					end
				end
			end
		end
	elseif rot1 and not rot2 then
		local _x1,_y1 = (o1x + h1 - r1.y), (o1y + r1.x)
		local _x2,_y2 = (o2x + r2.x), (o2y + r2.y)
		for i = 1,r1.w do
			for j = 1,r1.h do
				local _,_,_,a = i1:getRGBA(_x1 - j, _y1 + i)
				if a > a1 then
					_,_,_,a = i1:getRGBA(_x2 + i, _y2 + j)
					if a > a2 then
						return true
					end
				end
			end
		end
	elseif rot1 and rot2 then
		local _x1,_y1 = (o1x + h1 - r1.y), (o1y + r1.x)
		local _x2,_y2 = (o2x + h2 - r2.y), (o2y + r2.x)
		for i = 1,r1.w do
			for j = 1,r1.h do
				local _,_,_,a = i1:getRGBA(_x1 - j, _y1 + i)
				if a > a1 then
					_,_,_,a = i2:getRGBA(_x2 - j, _y2 + i)
					if a > a2 then
						return true
					end
				end
			end
		end
	end
    return false
end
