--[[---
A texture stores the information that represents an image. It cannot 
be added to the display list directly; instead it has to be mapped 
into a display object, that is the class "Image".

A Texture is a GPU bitmap object that can be diplayed o screen but cannot be modified at runtime.
It's created loading into GPU memory a CPU Bitmap.
--]]

Texture = class()

---Max widht of Texture object
Texture.MAX_WIDTH = 4096
---Max height of Texture object
Texture.MAX_HEIGHT = 4096

---GL_LINEAR filter
Texture.GL_LINEAR 					= MOAITexture.GL_LINEAR
---GL_LINEAR_MIPMAP_LINEAR filter
Texture.GL_LINEAR_MIPMAP_LINEAR 	= MOAITexture.GL_LINEAR_MIPMAP_LINEAR
---GL_LINEAR_MIPMAP_NEAREST filter
Texture.GL_LINEAR_MIPMAP_NEAREST	= MOAITexture.GL_LINEAR_MIPMAP_NEAREST
---GL_NEAREST filter
Texture.GL_NEAREST					= MOAITexture.GL_NEAREST
---GL_NEAREST_MIPMAP_LINEAR filter
Texture.GL_NEAREST_MIPMAP_LINEAR	= MOAITexture.GL_NEAREST_MIPMAP_LINEAR
---GL_NEAREST_MIPMAP_NEAREST filter
Texture.GL_NEAREST_MIPMAP_NEAREST	= MOAITexture.GL_NEAREST_MIPMAP_NEAREST

--[[---
Creates an empty, transparent texture of specific width and height
@tparam int width texture width
@tparam int height texture height
@treturn Texture empty texture
--]]
function Texture.empty(width, height)
	assert(width<=Texture.MAX_WIDTH and height <= Texture.MAX_HEIGHT)
	local img = MOAIImage.new()
	img:init(width,height)
    return Texture(img)
end

--[[---
Creates a texture of specific width and height and color
@tparam int width texture width
@tparam int height texture height
@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
@treturn Texture a texture filled with the given color
--]]
function Texture.fromColor(width, height, r, g, b, a)
	assert(width<=Texture.MAX_WIDTH and height <= Texture.MAX_HEIGHT)
	local img = MOAIImage.new()
	img:init(width,height)
	local r,g,b,a = Color._toNormalizedRGBA(r,g,b,a)
	img:fillRect (0,0,width,height,r,g,b,a)
    return Texture(img)
end


--[[---
Load an external file and create a texture. 
ColorTransform options can be provided, where PREMULTIPLY_ALPHA is the default value. 
If a texture is created with straight alpha, once the texture is assigned to a displayObj 
(image or subclasses) the premultiplyAlpha value of the object should be changed accordingly.

@tparam string fileName the name of the image file to load
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions
@treturn[1] Texture
@return[2] nil
@treturn[2] string error message
--]]
function Texture.fromFile(fileName, transformOptions)
	local srcData, err = BitmapData.fromFile(fileName, transformOptions)
	if not srcData then
		return nil, err
	end
	return Texture(srcData)
end


--[[---
Constructor.
Create a Texture starting from a MOAI object. 
@param srcData can be a MOAIImage (or a derived MOAIImageTexture), or a MOAIFrameBuffer
@tparam[opt=nil] Rect frame
--]]
function Texture:init(srcData, frame)
	--invalidate is a specific "MOAIImageTexture" (userdata) method
    if srcData.invalidate then
		self.srcData = srcData
		self.textureData = srcData
	--bleedRect is a specific "MOAIImage" (userdata) method
    elseif srcData.bleedRect then
		self.srcData = srcData
		self.textureData = MOAITexture.new()
		self.textureData:load(self.srcData)
	--getRenderTable is a specific "MOAIFrameBufferTexture" (userdata) method
    elseif srcData.getRenderTable then
		self.srcData = srcData
		self.textureData = srcData
	else
		error("Texture accept MOAIImage, MOAIImageTexture or MOAIFrameBufferTexture")
    end
	
	self.rotated = false
	self.trimmed = frame ~= nil
	self.region = Rect(0,0,self.textureData:getSize())
	self.frame = frame and frame:clone() or self.region
end


---When called textureData (MOAITexture) is released
function Texture:dispose()
	self.textureData:release()
	self.textureData = nil
	self.region = nil
	self.frame = nil
	self.srcData = nil
	self._quad = nil
end

--[[---
Returns srcData (the image on wich the texture was built) if available
@treturn MOAIImage
--]]
function Texture:getSrcData()
	return self.srcData
end

---release the srcData object if available (to save cpu memory if not needed)
function Texture:releaseSrcData()
	self.srcData = nil
end

--[[---
Set default filtering mode for texture, choosing between 
<ul>
<li>Texture.GL_LINEAR</li>
<li>Texture.GL_LINEAR_MIPMAP_LINEAR</li> 
<li>Texture.GL_LINEAR_MIPMAP_NEAREST</li> 
<li>Texture.GL_NEAREST</li>
<li>Texture.GL_NEAREST_MIPMAP_LINEAR</li>
<li>Texture.GL_NEAREST_MIPMAP_NEAREST</li>
</ul>
@param min
@param[opt=min] mag 
--]]
function Texture:setFilter(min, mag)
	self.textureData:setFilter(min, mag)
end

--[[---
Returns the width of the texture in pixels
@treturn int width
--]]
function Texture:getWidth()
	return self.frame.w
end

--[[---
Returns the height of the texture in pixels
@treturn int height
--]]
function Texture:getHeight()
	return self.frame.h
end

--[[---
Returns the size of the texture in pixels
@treturn int width
@treturn int height
--]]
function Texture:getSize()
	return self.frame.w, self.frame.h
end

--[[---
Returns the region as pixel rect over srcdata. It doesn't take care of the rotated flag
@tparam[opt=nil] Rect resultRect if provided is filled and returned
@treturn Rect
--]]
function Texture:getRegion(resultRect)
	local res = resultRect or Rect()
	res:copy(self.region)
	return res
end

function Texture:getFrame(resultRect)
	local res = resultRect or Rect()
	res:copy(self.frame)
	return res
end

--[[---
Returns the region as uv rect over srcdata. It doesn't take care of the rotated flag
@tparam[opt=nil] Rect resultRect if provided is filled and returned
@treturn Rect (values are [0..1])
--]]
function Texture:getRegionUV(resultRect)
	local res = self:getRegion(resultRect)
	local w,h = self.textureData:getSize()
	res.x, res.w = res.x / w, res.w / w
	res.y, res.h = res.y / h, res.h / h
	return res
end
	

--[[---
Returns the rect to be set into MOAI quad (either a single quad or an indexed quaddeck)
@treturn int x
@treturn int y
@treturn int w
@treturn int h
--]]
function Texture:_getQuadRect()
	local rw, rh
	if self.rotated then
		rw,rh = self.region.h, self.region.w
	else
		rw,rh = self.region.w, self.region.h
	end
	if __USE_SIMULATION_COORDS__ then
		return 	self.frame.x, 
				self.frame.h - (self.frame.y + rh), 
				self.frame.x + rw,
				self.frame.h - self.frame.y 
	else -- not __USE_SIMULATION_COORDS__
		return 	self.frame.x, 
				self.frame.y, 
				self.frame.x + rw, 
				self.frame.y + rh
	end
end

--[[---
if the texture is not rotated a region is mapped as a rect, with
y coords varying based on Shilke2D coordinate space
@tparam Rect r the region to transform
@treturn int x
@treturn int y
@treturn int w
@treturn int h
--]]
local function _region2rect(r)
	if __USE_SIMULATION_COORDS__ then
		return r.x, r.y + r.h, r.x + r.w, r.y
	else -- not __USE_SIMULATION_COORDS__
		return r.x, r.y, r.x + r.w, r.y + r.h
	end
end

--[[
if the texture is rotated a region is mapped as a quad, with
y coords varying based on Shilke2D coordinate space
@tparam Rect r the region to transform
@treturn int x1
@treturn int y1
@treturn int x2
@treturn int y2
@treturn int x3
@treturn int y3
@treturn int x4
@treturn int y4
--]]
local function _region2quad(r)
	if __USE_SIMULATION_COORDS__ then
		return	r.x + r.w, r.y,
				r.x + r.w, r.y + r.h,
				r.x, r.y + r.h,
				r.x, r.y
	else -- not __USE_SIMULATION_COORDS__
		return	r.x, r.y,
				r.x, r.y + r.h,
				r.x + r.w, r.y + r.h,
				r.x + r.w, r.y
	end
end


local __helperRect = Rect()

--[[---
Called to correctly map texture uv over quad. It can be used either for a single 
quad (like for texture quad generation) or for an indexed quaddeck (i.e. to build
shared texture sets from outside, or custom displayobject)
@param quad the external MOAIGfxQuad2D or MOAIGfxQuadDeck2D structure to be filled
@int[opt=nil] index if quad is a MOAIGfxQuadDeck2D a index of the quad/texture inside 
the quadDeck must be provided
--]]
function Texture:_fillQuadUV(quad, index)
	local r = self:getRegionUV(__helperRect)
	local params, func = nil, nil
	if self.rotated then
		params = {_region2quad(r)}
		func = quad.setUVQuad
	else
		params = {_region2rect(r)}
		func = quad.setUVRect
	end
	if index ~= nil then
		table.insert(params, 1, index)
	end
	func(quad, unpack(params))
end


--[[---
Inner method. 
Creates and caches a MOAIGfxQuad2D used and shared by Images to show the texture.
If a texture is not binded to an Image the MOAIGfxQuad2D is never created
@return MOAIGfxQuad2D
--]]
function Texture:_generateQuad()
	local quad = MOAIGfxQuad2D.new()
	quad:setTexture(self.textureData)
	quad:setRect(self:_getQuadRect())
	self:_fillQuadUV(quad)
	return quad
end

--[[---
Inner method. 
Creates and caches a MOAIGfxQuad2D used and shared by Images to show the texture.
If a texture is not binded to an Image the MOAIGfxQuad2D is never created
@return MOAIGfxQuad2D
--]]
function Texture:_getQuad()
	if not self._quad then
		self._quad = self:_generateQuad()
	end
	return self._quad
end
