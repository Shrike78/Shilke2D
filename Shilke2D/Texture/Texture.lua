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

--[[---
Creates an empty, transparent texture of specific width and height
@param width texture width
@param height texture height
@return empty texture
--]]
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
		_a = (a ~= nil) and (a / 255) or 1
	else
		_r, _g, _b, _a = r:unpack_normalized()
	end	
	img:fillRect (0,0,width,height,_r,_g,_b,_a)
    return Texture(img)
end

--[[---
Returns a render to texture of a given displayObj. The method could be pretty slow
if done using grabNextFrame so it should be used only on startup of a game or in setup of a new level
@param displayObj the displayObj that must be rendered on the newly created texture
@return Texture
--]]function Texture.fromDisplayObj(displayObj)
	local tmp = DisplayObjContainer()
	tmp:addChild(displayObj:clone())
	tmp:createFrameBufferImage(false)
	txt = tmp:getFrameBufferImage().texture
	return txt
end


--[[---
Returns a subtexture of the given texture, based on region definition
@param texture the texture from wich obtain a subtexture
@param region a rect that defines the subtexture, coords are expressed in pixel
@param rotated boolean (optional). if true the region is rotated of 90° clockwise
@param frame rect (optional). Defines a subtexture with a trimmed region. x,y 
indicates the offset of the mapping rect while w,h are real sprite width and height. 
@return SubTexture
--]]
function Texture.fromTexture(texture, region, rotated, frame)
	assert(class_type(texture) == Texture, "only object of class Texture can be used")
	assert(region, "A region must be provided")
	return SubTexture(texture,region,rotated,frame)
end


---Create a Texture starting from a MOAI object. 
--@param srcData can be a string (path), a MOAIImage, a MOAIImageTexture or a MOAIFrameBufferTexture
function Texture.fromData(srcData)
	return Texture(srcData)
end

---Constructor.
--Create a Texture starting from a MOAI object. 
--@param srcData can be a string (path) or a MOAIImageTexture or a MOAIImage or a MOAIFrameBufferTexture
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
	--MOAIFrameBufferTexture has lot of limitations (not getRGB, ecc.), can be just
	--used as drawable object.
    elseif srcData.getRenderTable then
		self.srcData = nil
		self.textureData = srcData
	else
		error("Texture accept image path, MOAIImage, MOAIImageTexture or MOAIFrameBufferTexture")
    end
    
	self.rotated = false
	self.trimmed = false
	self.frameX, self.frameY = 0, 0
	self.width, self.height = self.textureData:getSize()
	self.region = Rect(0,0,self.width,self.height)
end

--copy function must be implemented for each specific texture implementation
function Texture:copy()
	--this is specific for framebuffer textures.
	local srcData = self.srcData or self.textureData
	return Texture(srcData)
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

function Texture:updateTextureData(bReleaseFb)
	--This way it's possible to retrieve the MOAIImage instead of he framebufferimage.
	--it sould be slow so it's not so safe to use it, the risk is to have huge framerate 
	--drops. It could be anyway a good way to transform a generic 'displayobj' into an 
	--image. Anyway that would leave the possibility to update each frame the framebuffertexture
	if not self.srcData and self.textureData and self.textureData.getRenderTable then
		bReleaseFb = bReleaseFb or false
		local fbSrcData = MOAIImage.new()
		local cbFunc = function()
			print("update srcdata")
			self.srcData = fbSrcData
			if bReleaseFb then
				self.textureData:release()
			end
			self.textureData = MOAITexture.new()
			self.textureData:load(self.srcData) 
			self._quad:setTexture(self.textureData)
		end
		self.textureData:grabNextFrame(fbSrcData, cbFunc)
	else
		error("updateTextureData can be called only on textures generated by MOAIFrameBufferTexture")
	end
end

---Returns the base raw image. 
--@return MOAIImageTexture or MOAIImage
function Texture:image()
    return self.srcData
end

--[[---
Get value of the pixel at x,y coord as 32bit number
The function extends and wraps the original MOAIImage:getColor32
@param x x coord of the pixel
@param y y coord of the pixel
@return number 32bit rgba value
--]]
function Texture:getColor32(x,y)
	if not self.srcData then
		print("warning: Texture:getColor32 called on a Texture generated by MAOIFrameBufferTexture") 
		return 0
	end
	return self.srcData:getColor32(x,y)
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
	if not self.srcData then
		print("warning: Texture:getRGBA called on a Texture generated by MAOIFrameBufferTexture") 
		return 0,0,0,0
	end
	return self.srcData:getRGBA(x,y)
end

--[[---
Get Color value of the pixel at x,y coord
Color values are in the range [0,255]
@param x x coord of the pixel
@param y y coord of the pixel
@return Color
--]]
function Texture:getColor(x,y)
	return Color.fromNormalizedValues(self:getRGBA(x,y))
end

if __USE_SIMULATION_COORDS__ then
	--[[---
	if the texture is not rotated a region is mapped as a rect, with
	y coords varying based on Shilke2D coordinate space
	@param r the 
	--]]
	function Texture._region2rect(r)
		return r.x, r.y + r.h, r.x + r.w, r.y
	end

	--[[---
	if the texture is rotated a region is mapped as a quad, with
	y coords varying based on Shilke2D coordinate space
	@param r the 
	--]]
	function Texture._region2quad(r)
		return	r.x + r.w, r.y,
				r.x + r.w, r.y + r.h,
				r.x, r.y + r.h,
				r.x, r.y
	end
else --__USE_SIMULATION_COORDS__
	function Texture._region2rect(r)
		return r.x, r.y, r.x + r.w, r.y + r.h
	end

	function Texture._region2quad(r)
		return	r.x, r.y,
				r.x, r.y + r.h,
				r.x + r.w, r.y + r.h,
				r.x + r.w, r.y
	end
end

local __helperRect = Rect()

--[[---
Inner method. Called internally to correctly map texture uv
@param quad the external MOAIGfxQuad2D structure to be filled
--]]
function Texture:_fillQuadUV(quad)
	local r = self:getRegionUV(__helperRect)
	if not self.rotated then
		quad:setUVRect( self._region2rect(r) )
	else
		quad:setUVQuad( self._region2quad(r) ) 
	end
end

--[[---
Inner method. Called by objects that maps quaddecklists over textures (like tilesets)
to fill the quadDeck related to the current texture
@param quadDeck the external MOAIGfxQuadDeck2D structure to be filled
@param index the index of this texture inside the quadDeck
--]]
function Texture:_fillQuadDeckUV(quadDeck, index)
	local r = self:getRegionUV(__helperRect)
	if not self.rotated then
		quadDeck:setUVRect(index, self._region2rect(r) )
	else
		quadDeck:setUVQuad(index, self._region2quad(r) )
	end
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
		local rw, rh
		if self.rotated then
			rw,rh = self.region.h, self.region.w
		else
			rw,rh = self.region.w, self.region.h
		end
		if __USE_SIMULATION_COORDS__  then
			self._quad:setRect(self.frameX, 
								self.height - (self.frameY + rh), 
								self.frameX + rw,
								self.height - self.frameY 
				)
		else --__USE_SIMULATION_COORDS__
			self._quad:setRect(self.frameX, 
								self.frameY, 
								self.frameX + rw, 
								self.frameY + rh
						)
		end
		self:_fillQuadUV(self._quad)
	end
	return self._quad
end

---Returns the rect enclosing the image
--@param resultRect if provided is filled and returned
--@return Rect
function Texture:getRect(resultRect)
	local res = resultRect or Rect()
	res.x = 0
	res.y = 0
	res.w = self.width
	res.h = self.height
	return res
end

---Returns the width of the texture in pixels
--@return int
function Texture:getWidth()
	return self.width
end

---Returns the height of the texture in pixels
--@return int
function Texture:getHeight()
	return self.height
end

---Returns the region as pixel rect over srcdata. It doesn't take care of the rotated flag
--@param resultRect if provided is filled and returned
--@return Rect
function Texture:getRegion(resultRect)
	local res = resultRect or Rect()
	res:copy(self.region)
	return res
end


---Returns the region as uv rect over srcdata. It doesn't take care of the rotated flag
--@param resultRect if provided is filled and returned
--@return Rect (values are [0..1])
function Texture:getRegionUV(resultRect)
	local res = resultRect or Rect()
	res.x, res.y, res.w, res.h = 0,0,1,1
	return res
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
	assert(self.srcData and texture2.srcData,  "Texture:hitTest called on Texture generated by MAOIFrameBufferTexture") 
	local p1 = p1
	if self.trimmed then
		p1 = p1 + vec2(self.frameX, self.frameY)
	end
	local p2 = p2
	if texture2.trimmed then
		p2 = p2 + vec2(texture2.frameX, texture2.frameY)
	end
	return imageHitTestEx(
				self.srcData,p1,a1,
				texture2.srcData,p2,a2,
				self.region,
				texture2.region,
				self.rotated,
				texture2.rotated
			)
end
