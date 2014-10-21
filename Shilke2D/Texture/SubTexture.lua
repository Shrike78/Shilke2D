--[[---
A SubTexture represents a section of another texture. 
It's not possible to create subtextures of subtextures.
--]]

--[[---
Returns a subtexture of the given texture, based on region definition
@param texture the texture from wich obtain a subtexture
@param region a rect that defines the subtexture, coords are expressed in pixel
@param rotated boolean (optional). if true the region is rotated of 90° clockwise
@param frame rect (optional). Defines a subtexture with a trimmed region. x,y 
indicates the offset of the mapping rect while w,h are real sprite width and height. 
@treturn SubTexture
--]]
function Texture.fromTexture(texture, region, rotated, frame)
	assert(not texture.parent, "SubTexture of SubTexture is not supported")
	return SubTexture(texture,region,rotated,frame)
end


SubTexture = class(Texture)

--[[---
Constructor.
A sub texture is created as sub region of another texture.
The regions can be 90° clockwise rotated. 
@tparam Texture parentTexture the src texture from which the subtexture is created
@tparam Rect region the region that defines the sub texture
@tparam[opt=false] bool rotated If true the region is 90° clockwise rotated
@tparam[opt=region] frame if the src image has been trimmed when packed in a atlas, frame
must be provided to correctly identify real texture size / rect
--]]
function SubTexture:init(parentTexture, region, rotated, frame)
    self.parent = parentTexture
    self.textureData = self.parent.textureData
	self.region = region:clone()
	self.rotated = (rotated == true)
	if frame then
		self.trimmed = true
		self.frame = frame:clone()
	else
		self.trimmed = false
		if self.rotated then
			self.frame = Rect(0, 0, self.region.h, self.region.w)
		else
			self.frame = Rect(0, 0, self.region.w, self.region.h)
		end
	end
end

---Dispose doesn't release textureData but release every reference to textureData.
function SubTexture:dispose()
	self.parent = nil
	self.textureData = nil
	self.region = nil
	self.frame = nil
	self._quad = nil
end

function SubTexture:getSrcData()
	return self.parent.srcData
end

function SubTexture:releaseSrcData()
	--should release supr parent src data or just do nothing?
	--return self.parent:releaseSrcData()
end



