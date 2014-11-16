--[[---
A texture stores the information that represents an image. It cannot 
be added to the display list directly; instead it has to be mapped 
into a display object, that is the class "Image".

Texture derives from BitmapRegion and it's a region of a GPU bitmap object 
that can be diplayed on screen but cannot be modified at runtime.

It's created loading into GPU memory a CPU Bitmap.
--]]

Texture = class(BitmapRegion)

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
		self.textureData = srcData
	--bleedRect is a specific "MOAIImage" (userdata) method
    elseif srcData.bleedRect then
		self.textureData = MOAITexture.new()
		self.textureData:load(srcData)
	--getRenderTable is a specific "MOAIFrameBufferTexture" (userdata) method
    elseif srcData.getRenderTable then
		self.textureData = srcData
	else
		error("Texture accept MOAIImage, MOAIImageTexture or MOAIFrameBufferTexture")
    end
	BitmapRegion.init(self, Rect(0,0,self.textureData:getSize()), false, frame)
end


---When called textureData (MOAITexture) is released
function Texture:dispose()
	BitmapRegion.dispose(self)
	self.textureData:release()
	self.textureData = nil
	self._quad = nil
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


-- Private methods

--[[---
Inner method. 
Returns region unwrapped as MOAIGfxQuad rect coordinates
@treturn int x1
@treturn int y1
@treturn int x2
@treturn int y2
--]]
function Texture:_getQuadRect()
	local rw, rh = self.region.w, self.region.h
	if self.rotated then
		rw,rh = rh,rw 
	end
	local x0,y0,x1,y1 = self.frame.x, self.frame.y, self.frame.x + rw, self.frame.y + rh
	if __USE_SIMULATION_COORDS__ then
		local frameh = self.frame.h
		y0,y1 = frameh-y1, frameh-y0
	end
	return 	x0,y0,x1,y1
end

--[[---
Inner method. 
Returns region unwrapped as MOAIGfxQuad UV coordinates
@treturn int u1
@treturn int v1
@treturn int u2
@treturn int v2
@treturn int u3
@treturn int v3
@treturn int u4
@treturn int v4
--]]
function Texture:_getQuadUV()
	local srcw, srch = self.textureData:getSize()
	local x0, w = self.region.x / srcw, self.region.w / srcw
	local y0, h = self.region.y / srch, self.region.h / srch
	local x1,y1 = x0+w,y0+h
	if self.rotated then
		if __USE_SIMULATION_COORDS__ then
			x0,x1 = x1,x0
		end
		return x0,y0, x0,y1, x1,y1, x1,y0
	else
		if __USE_SIMULATION_COORDS__ then
			y0,y1 = y1,y0
		end
		return x0,y1, x1,y1, x1,y0, x0,y0
	end
end


--[[---
Inner method. 
Creates and caches a MOAIGfxQuad2D used and shared by Images to show the texture.
If a texture is not binded to an Image the MOAIGfxQuad2D is never created
@treturn MOAIGfxQuad2D
--]]
function Texture:_generateQuad()
	local quad = MOAIGfxQuad2D.new()
	quad:setTexture(self.textureData)
	quad:setRect(self:_getQuadRect())
	quad:setUVQuad(self:_getQuadUV(self.textureData))
	return quad
end

--[[---
Inner method. 
Creates and caches a MOAIGfxQuad2D used and shared by Images to show the texture.
If a texture is not binded to an Image the MOAIGfxQuad2D is never created
@treturn MOAIGfxQuad2D
--]]
function Texture:_getQuad()
	if not self._quad then
		self._quad = self:_generateQuad()
	end
	return self._quad
end
