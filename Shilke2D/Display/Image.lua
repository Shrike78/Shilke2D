--[[--- 
An Image is the Shilke2D equivalent of Flash's Bitmap class. 
Instead of BitmapData, Shilke2D uses textures to represent the 
pixels of an image.
--]]

Image = class(BaseQuad)

--[[---
At init phase it's possible to set a texture and a pivotMode.
@param texture a Texture or nil.
@param pivotMode default pivotMode is CENTER
--]]
function Image:init(texture, pivotMode)
	if texture then
		BaseQuad.init(self,texture.width,texture.height,pivotMode)
		self.texture = texture
		self._prop:setDeck(texture:_getQuad())
	else
		BaseQuad.init(self,0,0,pivotMode)
		self.texture = nil
	end
	self.ppHitTest = false
	self.ppAlphaLevel = 0
end

function Image:dispose()
	BaseQuad.dispose(self)
	self.texture = nil
end

function Image:copy(src)
	BaseQuad.copy(self, src)
	self:setTexture(src:getTexture())
end

---For images is possible to force the hitTest to be pixel precise on texture pixels
--@param enabled boolean enable/disable pixelPrecise hitTest
--@param alphaLevel if prixelPrecise hitTest is enabled this value define the alpha treshold to consider
--pixel transparent. Default value is 0
function Image:setPixelPreciseHitTest(enabled,alphaLevel)
	self.ppHitTest = enabled
	if enabled then
		self.ppAlphaLevel = alphaLevel ~= nil and alphaLevel/255 or 0
	end
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
				local a
				if __USE_SIMULATION_COORDS__ then
					_,_,_,a = self.texture:getRGBA(_x-r.x, -_y-r.y)
				else
					_,_,_,a = self.texture:getRGBA(_x-r.x, _y-r.y)
				end
				if a > self.ppAlphaLevel then
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

-- public methods


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
		
			--if first set (called by init) or texture switch between
			--subtexture of the same texture atlas, an update is
			--required only if the shape changes
			local bUpdateGeometry = not self.texture or 
				(self.texture.width ~= texture.width) or 
				(self.texture.height ~= texture.height)
			self.texture = texture
			self._prop:setDeck(texture:_getQuad())
			if bUpdateGeometry then
				self:setSize(texture.width,texture.height)
			end
		end
	end
end

---Returns the current texture
--@return texture
function Image:getTexture()
	return self.texture
end
