-- SubTexture

--[[
A SubTexture represents a section of another texture. This is achieved
solely by manipulation of texture coordinates, making the class very 
efficient. 

NB
It's not possible at now to create subtextures of subtextures but
adding support if needed should be an easy task because the only needs
is to obtains sub regions of super region
--]]

SubTexture = class(Texture)

-- rotated means that the region is 90* clockwise rotated, so once loaded must be anticlockwise
-- mapped. That require custom handling of several things like raw image cache creation and hitTest
function SubTexture:init(parentTexture, region, rotated)
    
    self.parent = parentTexture
    self.textureData = self.parent.textureData
    self.srcData = self.parent.srcData
    
    self.region = region
	self.rotated = rotated
	if not self.rotated then
		self.width = math.round(self.parent.width * self.region.w)
		self.height = math.round(self.parent.height * self.region.h)
	else
		self.height = math.round(self.parent.width * self.region.w)
		self.width = math.round(self.parent.height * self.region.h)
	end
    self.cahedImage = {}
    setmetatable(self.cahedImage,{__mode="v"})
end

function SubTexture:dispose()
	if self.textureData then
		self.parent = nil
		self.textureData = nil
		self.srcData = nil
		self.region = nil
		self._quad = nil
		self.cahedImage[1] = nil
	end
end

function SubTexture:_getRect()
	local w,h = self.parent.width, self.parent.height
	local r = Rect(math.round(self.region.x * w),
					math.round(self.region.y * h),
					math.round(self.region.w * w),
					math.round(self.region.h * h))
	return r
end

--[[
return a raw image that rapresent the subtexture. To do that 
it needs to create a new image, set as context and draw the region 
of the original texture.
after that it caches the resulting image so it's already available 
for next request.
--]]
function SubTexture:image()
    local img = self.cahedImage[1]
    if not img then
							
        img = MOAIImage.new()
		img:init(self.width, self.height, self.srcData:getFormat())
		if not self.rotated then 
			img:copyBits(	self.parent.srcData, 
							math.round(self.region.x * self.parent.width),
							math.round(self.region.y * self.parent.height),
							0, 0, self.width, self.height)
		else
			local r = self:_getRect()
			for i = 1, self.height do
				for j = 1, self.width do
					local x = r.x + r.w - i
					local y = r.y + j
					img:setColor32(j,i,self.srcData:getColor32(x,y))
				end
			end
		end
		self.cahedImage[1] = img
    end
    return img
end

function SubTexture:getRGBA(x,y)
	if not self.rotated then
		local x = self.region.x * self.parent.width + x
		local y = self.region.y * self.parent.height + y
		return self.srcData:getRGBA(x,y)
	else
		local x = self.region.x * self.parent.width + self.height - y
		local y = self.region.y * self.parent.height + x
		return self.srcData:getRGBA(x,y)
	end
end
