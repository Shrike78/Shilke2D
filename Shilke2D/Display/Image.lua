--[[--- 
An Image is a 2d quad with a mapped texture.
It's possible to see Image and Texture as equivalent of flash's Bitmap / BitmapData.
--]]

Image = class(BaseQuad)

--[[---
At init phase it's possible to set a texture and a pivotMode.
@param texture a Texture or nil.
@param pivotMode default pivotMode is CENTER
--]]
function Image:init(texture, pivotMode)
	if texture then
		BaseQuad.init(self,texture:getWidth(),texture:getHeight(),pivotMode)
		self.texture = texture
		self._prop:setDeck(texture:_getQuad())
	else
		BaseQuad.init(self,0,0,pivotMode)
		self.texture = nil
	end
	self.ppHitTest = nil
end


---clear inner structs
function Image:dispose()
	BaseQuad.dispose(self)
	self.texture = nil
end

--[[---
Return a new Image that shares the same texture
@param bClonePivot boolean if true set the same pivotMode / pivot point, 
else set defaul pivotMode CENTER
@return Image
--]]
function Image:clone(bClonePivot)
    if not bClonePivot then
        return Image(self.texture)
    else
        local obj = Image(self.texture,self._pivotMode)
        if self._pivotMode == PivotMode.CUSTOM then
            obj:setPivot(self:getPivot())
        end
        return obj
    end
end

--[[---
Set a new texture.

If the new and the old textures shared the same textureData
the switch is just an uv switch, else a full texture switch

It would be preferrable that all the textures that can 
be assigned to a specific image belongs to the same 
texture atlas.
@param texture the new texture to be set for the image
--]]
function Image:setTexture(texture)
    if self.texture ~= texture then
		if not texture then
			self.texture = nil
			self._prop:setDeck(nil)
			self:setSize(0,0)
		else
			self.texture = texture
			self._prop:setDeck(texture:_getQuad())
			local tw, th = texture:getSize()
			if (self.width ~= tw) or (self.height ~= th) then
				self:setSize(tw,th)
			end
		end
	end
end

---Returns the current texture
--@return texture
function Image:getTexture()
	return self.texture
end


--[[---
For images is possible to force the hitTest to be pixel precise on texture pixels
Usually an image of the same size of the wrapped texture should be provide, but
it's also possible to provide an image of different size (usually smaller to reduce 
used memory)
@tparam int alphaLevel alpha treshold to consider a pixel as invisible pixel
@tparam MOAIImage image
@tparam[opt=nil] BitmapRegion bmpRegion
--]]
function Image:enablePixelPreciseHitTest(alphaLevel, image, bmpRegion)
	local alphaLevel = alphaLevel or 0
	local _w,_h
	if bmpRegion then
		_w,_h = bmpRegion:getSize()
	else
		_w,_h = image:getSize()
	end
	self.ppHitTest = 
	{
		alphaLevel = alphaLevel/255,
		image = image,
		bitmapRegion = bmpRegion,
		w = _w,
		h = _h
	}
end

---Disable the pixel precision hit test 
function Image:disablePixelPreciseHitTest()
	self.ppHitTest = nil
end

--[[---
If pixelPrecise hitTest is enabled the hitTest is made on texture pixel alpha value
else using normal point into box test
@param x coordinate in targetSpace system
@param y coordinate in targetSpace system
@param targetSpace the referred coorindate system. If nil the top most container / stage
@param forTouch boolean. If true the check is done only for visible and touchable object
@return self if the hitTest is positive else nil 
--]]
function Image:hitTest(x,y,targetSpace,forTouch)
	if not forTouch or (self._visible and self._touchable) then
		local _x,_y
		if targetSpace == self then
			_x,_y = x,y
		else
			_x,_y = self:globalToLocal(x,y,targetSpace)
		end
		
		local r = self:getRect(__helperRect)
		if r:containsPoint(_x,_y) then
			if self.ppHitTest then
				local img = self.ppHitTest.image
				local bmpRegion = self.ppHitTest.bitmapRegion
				local alphaLevel = self.ppHitTest.alphaLevel
				local rw = self.ppHitTest.w / self._width
				local rh = self.ppHitTest.h / self._height
				_x, _y = _x * rw, _y * rh
				local _,_,_,a = BitmapData.getRGBA(img, _x, _y, bmpRegion)
				if a > alphaLevel then
					return self
				else
					return nil
				end
			else
				return self
			end
		end
	end
	return nil	
end
