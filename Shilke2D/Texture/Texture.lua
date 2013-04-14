--[[---
A texture stores the information that represents an image. It cannot 
be added to the display list directly; instead it has to be mapped 
into a display object, that is the class "Image".

Textures are flash equivalent of BitmapData, as well as Images are equivalent of Bitmap.

It's possible to create a texture using a sub region of another texture. Resulting texture is
a SubTexture.

There's no practical difference between a Texture and a SubTexture, they work as the same once added 
to a Image
--]]

Texture = class()

---Creates an empty, transparent texture of specific width and height
--@param width texture width
--@param height texture height
--@return empty texture
function Texture.empty(width, height)
	local img = MOAIImage.new()
	img:init(width,height)
    return Texture(img)
end

--[[---
Creates a texture of specific width and height and color
@param width texture width
@param height texture height
@param r red value [0,255] or a Color
@param g green value [0,255] or nil
@param b blue value [0,255] or nil
@param a alpha value [0,255] or nil
@return Texture
--]]
function Texture.fromColor(width, height, r, g, b, a)
	local img = MOAIImage.new()
	img:init(width,height)
	local _r,_g,_b,_a
	if type(r) == 'number' then
		_r = r/255
		_g = g/255
		_b = b/255
		_a = a and a / 255 or 1
	else
		_r, _g, _b, _a = r:unpack_normalized()
	end	
	img:fillRect (0,0,width,height,_r,_g,_b,_a)
    return Texture(img)
end

--Returns a subtexture of the given texture, based on region definition
--if region is (0,0,1,1) then return the texture itself
--@param texture the texture from wich obtain a subtexture
--@param region a rect that defines the subtexture, coords are expressed as [0,1]
--@param rotated boolean. if true the region is rotated of 90° clockwise
--@return SubTexture
function Texture.fromTexture(texture, region, rotated)
    if region.x == 0 and region.y == 0 and 
        region.w == 1 and region.h == 1 then
            return texture
    else
        return SubTexture(texture,region,rotated)
    end
end


---Constructor.
--Create a Texture starting from a MOAI object. 
--@param srcData can be a string (path) or a MOAIImageTexture or a MOAIImage
function Texture:init(srcData)
	--Path to a png image
    if type(srcData) == 'string' then
		self.srcData = MOAIImage.new()
		self.srcData:load(srcData)
		self.textureData = MOAITexture.new()
		self.textureData:load(self.srcData)
	--invalidate is a specific "MOAIImageTexture" (userdata) method
    elseif srcData.invalidate then
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
		error("Texture accept image path, MOAIImage, MOAIImageTexture or MOAIFrameBufferTexture")
    end
    
	self.width, self.height = self.textureData:getSize()
	self.region = Rect(0,0,1,1)
	self.rotated = false
end

---When called textureData (MOAITexture) is released
function Texture:dispose()
	if self.textureData then
		self.textureData:release()
		self.textureData = nil
		self.srcData = nil
		self.region = nil
		self._quad = nil
	end
end

---Returns the base raw image. 
--@return MOAIImageTexture or MOAIImage
function Texture:image()
    return self.srcData
end

--[[---
Get rgba value of the pixel at x,y coord
The function extends and wraps the original MOAIImage:getRGBA and use the same space, so 
returns values in the range [0,1]
@param x x coord of the pixel
@param y y coord of the pixel
@return r,g,b,a [0,1]
--]]
function Texture:getRGBA(x,y)
	return self.srcData:getRGBA(x,y)
end

--[[---
Get Color value of the pixel at x,y coord
Color values are in the range [0,255]
@param x x coord of the pixel
@param y y coord of the pixel
@return Color [0,1]
--]]
function Texture:getColor(x,y)
	local r,g,b,a = self.srcData:getRGBA(x,y)
	return Color(r*255,g*255,b*255,a*255)
end


--[[---
Inner method. 
Creates and caches a MOAIGfxQuad2D used and shared by Images to show the texture.
If a texture is not binded to an Image the MOAIGfxQuad2D is never created
@return MOAIGfxQuad2D
--]]
function Texture:_getQuad()
    if not self._quad then
        self._quad = MOAIGfxQuad2D.new()
        self._quad:setTexture(self.textureData)
        local r = self.region
		if not self.rotated then
if __USE_SIMULATION_COORDS__ then
			self._quad:setUVRect(r.x, r.y + r.h, r.x + r.w, r.y )
else
			self._quad:setUVRect(r.x, r.y, r.x + r.w, r.y + r.h )
end
		else
if __USE_SIMULATION_COORDS__ then
			self._quad:setUVQuad (	
									r.x + r.w, r.y,
									r.x + r.w, r.y + r.h,
									r.x, r.y + r.h,
									r.x, r.y
							)
else
			self._quad:setUVQuad (	
									r.x, r.y,
									r.x, r.y + r.h,
									r.x + r.w, r.y + r.h,
									r.x + r.w, r.y
							)
end
		end
        self._quad:setRect(0, 0, self.width, self.height)
    end
    return self._quad
end


---Returns the rect enclosing the image
--@return Rect
function Texture:_getRect()
	local r = Rect(0,0, self.width, self.height)
	return r
end

--[[---
Pixel collision hitTest between 2 textures.
The two points considered are logical 0,0, that 
can be top left or bottom left point depending on 
__USE_SIMULATION_COORDS__ value
   
@param p1 top/bottom left position (vec2) of the texture
@param a1 alpha treshold to consider texture1 pixel transparent
@param texture2 texture to check collision with
@param p2 top/bottom left position (vec2) of texture2
@param a2 alpha treshold to consider texture2 pixel transparent
--]]
function Texture:hitTest(p1,a1,texture2,p2,a2)
    return imageHitTestEx(self.srcData,p1,a1,
        texture2.srcData,p2,a2,
		self:_getRect(),
		texture2:_getRect(),
		self.rotated,
		texture2.rotated)
end
