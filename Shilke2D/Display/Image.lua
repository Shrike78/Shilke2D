-- Image

--[[ 
An Image is the Shilke2D equivalent of Flash's Bitmap class. 
Instead of BitmapData, Shilke2D uses textures to represent the 
pixels of an image.
--]]

Image = class(FixedSizeObject)

function Image:init(texture, pivotMode)
	if texture then
		FixedSizeObject.init(self,texture.width,texture.height,pivotMode)
		self.texture = texture
		self._prop:setDeck(texture:_getQuad())
	else
		FixedSizeObject.init(self,0,0,pivotMode)
		self.texture = nil
	end
	self.ppHitTest = false
	self.ppAlphaLevel = 0
end

function Image:dispose()
	FixedSizeObject.dispose(self)
	self.texture = nil
end

function Image:setPixelPreciseHitTest(enabled,alphaLevel)
	self.ppHitTest = enabled
	if enabled then
		self.ppAlphaLevel = alphaLevel ~= nil and alphaLevel/255 or 0
	end
end

function Image:hitTest(x,y,targetSpace,forTouch)
	if not forTouch or (self._visible and self._touchable) then
		local _x,_y
		if targetSpace == self then
			_x,_y = x,y
		else
			_x,_y = self:globalToLocal(x,y,targetSpace)
		end
		
		local r = self:getBounds(self,__helperRect)
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

-- public 
--the clone method return a new Image that shares the same texture
--of the original image. It's possible to clone also
--pivot mode / position
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

--[[
If the new and the old textures shared the same textureData
the switch is just an uv switch, else a full texture switch

It would be preferrable that all the textures that can 
be assigned to a specific image belongs to the same 
texture atlas, to avoid texturedata switch at container level
that requires mesh quads pool management, possible creation of 
a new quad, a forced updategeometry, ecc. 
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

function Image:getTexture()
	return self.texture
end
