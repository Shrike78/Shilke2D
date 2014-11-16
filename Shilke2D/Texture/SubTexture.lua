--[[---
A SubTexture represents a section of another texture. 
It's not possible to create subtextures of subtextures.
--]]

--[[---
Returns a subtexture of the given texture, based on region definition
@function Texture.fromTexture
@param texture the texture from wich obtain a subtexture
@tparam BitmapRegion region the region that defines the sub texture
@treturn SubTexture
--]]

--[[---
Returns a subtexture of the given texture, based on region definition
@tparam Texture texture the texture from wich obtain a subtexture
@tparam Rect region a rect that defines the subtexture, coords are expressed in pixel
@tparam bool[opt=false] rotated if true the region is rotated of 90° clockwise
@tparam[opt=nil] Rect frame defines a subtexture with a trimmed region. x,y 
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
@function SubTexture:init
@tparam Texture parentTexture the src texture from which the subtexture is created
@tparam BitmapRegion region the region that defines the sub texture
--]]

--[[---
Constructor.
A sub texture is created as sub region of another texture.
The regions can be 90° clockwise rotated. 
@tparam Texture parentTexture the src texture from which the subtexture is created
@tparam Rect region the region that defines the sub texture
@tparam[opt=false] bool rotated If true the region is 90° clockwise rotated
@tparam[opt=region] Rect frame if the src image has been trimmed when packed in a atlas, frame
must be provided to correctly identify real texture size / rect
--]]
function SubTexture:init(parentTexture, region, rotated, frame)
    self.parent = parentTexture
    self.textureData = self.parent.textureData
	BitmapRegion.init(self, region, rotated, frame)
end

---Dispose doesn't release textureData but release every reference to textureData.
function SubTexture:dispose()
	BitmapRegion.dispose(self)
	self.parent = nil
	self.textureData = nil
	self._quad = nil
end


