--[[---
A SubTexture represents a section of another texture. 
It's not possible at now to create subtextures of subtextures.
--]]

SubTexture = class(Texture)

--[[---
Constructor.
A sub texture is created as sub region of another texture.
The regions can be 90° clockwise rotated. 
@param parentTexture the src texture from which the subtexture is created
@param region the region that defines the sub texture
@param rotated boolean value. If true the region is 90° clockwise rotated
--]]
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

---Dispose doesn't release textureData but release every reference to textureData.
function SubTexture:dispose()
	if self.textureData then
		self.parent = nil
		self.textureData = nil
		self.srcData = nil
		self.region = nil
		self._quad = nil
		if self.cahedImage[1] then
			self.cahedImage[1]:release()
			self.cahedImage[1] = nil
		end
	end
end

---The rect is obtained as product of the region values and the parent texture width and height
--@return Rect
function SubTexture:getRect()
	local w,h = self.parent.width, self.parent.height
	local r = Rect(math.round(self.region.x * w),
					math.round(self.region.y * h),
					math.round(self.region.w * w),
					math.round(self.region.h * h))
	return r
end

--[[---
Returns a raw image that rapresent the subtexture. To do that 
it needs to create a new image obtained copying pixels from the 
parent texture.
It caches the resulting image so it's already available 
for next requests.
@return MOAIImage
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
			local r = self:getRect()
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

--[[---
Get rgba value of the pixel at x,y coord
Override Texture:getRGBA because needs to remap x,y coords on parent texture.
The function extends and wraps the original MOAIImage:getRGBA and use the same space, so 
returns values in the range [0,1]
@param x x coord of the pixel
@param y y coord of the pixel
@return r,g,b,a [0,1]
--]]
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
