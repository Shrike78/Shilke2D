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
@param frame if the src image has been trimmed when packed in a atlas, frame
must be provided to correctly identify real texture size / rect
--]]
function SubTexture:init(parentTexture, region, rotated, frame)
    
    self.parent = parentTexture
    self.textureData = self.parent.textureData
    self.srcData = self.parent.srcData
    
    self.region = region
	self.rotated = (rotated == true)
	
	if frame then
		self.trimmed = true
		self.frameX, self.frameY = frame.x, frame.y
		self.width, self.height = frame.w, frame.h
	else
		self.trimmed = false
		self.frameX, self.frameY = 0, 0
		if self.rotated then
			self.width, self.height = self.region.h, self.region.w
		else
			self.width, self.height = self.region.w, self.region.h
		end
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

--SubTexture copy implementation
function SubTexture:copy()
	return SubTexture(self.parent, self.region, self.rotated)
end

---Returns the region as uv rect over srcdata. It doesn't take care of the rotated flag
--@param resultRect if provided is filled and returned
--@return Rect (values are [0..1])
function SubTexture:getRegionUV(resultRect)
	local res = self:getRegion(resultRect)
	res.x, res.w = res.x / self.parent.width, res.w / self.parent.width
	res.y, res.h = res.y / self.parent.height, res.h / self.parent.height
	return res
end

--[[---
Returns a raw image rapresenting the subtexture. It creates a
new image obtained copying pixels from the parent texture.
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
							self.region.x,
							self.region.y,
							self.frameX, self.frameY, 
							self.region.w, self.region.h)
		else
			for i = 0, self.region.w do
				for j = 0, self.region.h do
					local x = self.region.x + (self.region.w - 1) - i 
					local y = self.region.y + j
					img:setColor32(self.frameX + j, self.frameY + i, self.srcData:getColor32(x,y))
				end
			end
		end
		self.cahedImage[1] = img
    end
    return img
end


if __USE_SIMULATION_COORDS__ then
	
	function SubTexture:_getColor(x, y, colorFunc, defColorFunc)
		if self.trimmed then
			local rh,rw
			if self.rotated then
				rh,rw = self.region.w, self.region.h
			else
				rh,rw = self.region.h, self.region.w
			end
			if x < self.frameX or x > self.frameX + rw then
				return defColorFunc()
			elseif y < (self.height - self.frameY - rh) or y > (self.height - self.frameY) then
				return defColorFunc()
			end
			x = x - self.frameX
			y = y - (self.height - self.frameY - rh)
		end
		local _x, _y = self.region.x, self.region.y
		if not self.rotated then
			_x = _x + x
			_y = _y + self.region.h - y
		else
			_x = _x + y 
			_y = _y + x
		end
		return colorFunc(self.srcData,_x,_y)
	end
		
else --__USE_SIMULATION_COORDS__
	
	function SubTexture:_getColor(x, y, colorFunc, defColorFunc)
		if self.trimmed then
			local rh,rw
			if self.rotated then
				rh,rw = self.region.w, self.region.h
			else
				rh,rw = self.region.h, self.region.w
			end
			if x < self.frameX or x > self.frameX + rw then
				return defColorFunc()
			elseif y < self.frameY or y > self.frameY + rh then
				return defColorFunc()
			end
			x = x - self.frameX
			y = y - self.frameY
		end
		local _x, _y = self.region.x, self.region.y
		if not self.rotated then
			_x = _x + x
			_y = _y + y
		else
			_x = _x + (self.region.w - 1) - y 
			_y = _y + x
		end
		return colorFunc(self.srcData,_x,_y)
	end
	
end


local function defColor32()
	return 0
end

local function defRGBA()
	return 0,0,0,0
end

--[[---
Get value of the pixel at x,y coord as 32bit number
Override Texture:getColor32 because needs to remap x,y coords on parent texture.
The function extends and wraps the original MOAIImage:getColor32
@param x x coord of the pixel
@param y y coord of the pixel
@return number 32bit rgba value
--]]
function SubTexture:getColor32(x,y)
	return self:_getColor(x,y,self.srcData.getColor32,defColor32)
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
	return self:_getColor(x,y,self.srcData.getRGBA,defRGBA)
end
