 -- Texture 

--[[
A texture stores the information that represents an image. It cannot 
be added to the display list directly; instead it has to be mapped 
into a display object, that is the class "Image".
--]]

Texture = class()

function Texture.empty(width, height)
	local img = MOAIImage.new()
	img:init(width,height)
    return Texture(img)
end

--Return the subtexture of the given texture, based on region definition
--if region is (0,0,1,1) then return texture
function Texture.fromTexture(texture, region, rotated)
    if region.x == 0 and region.y == 0 and 
        region.w == 1 and region.h == 1 then
            return texture
    else
        return SubTexture(texture,region,rotated)
    end
end

-- Texture methods

--accepts a MOAIImage or a path
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
	else
		error("Texture accept image path, MOAIImage or MOAIImageTexture")
    end
    
	self.width, self.height = self.textureData:getSize()
	self.region = Rect(0,0,1,1)
	self.rotated = false
end

function Texture:dispose()
	if self.textureData then
		self.textureData:release()
		self.textureData = nil
		self.srcData = nil
		self.region = nil
		self._quad = nil
	end
end

--return the base raw image. 
function Texture:image()
    return self.srcData
end

function Texture:getRGBA(x,y)
	return self.srcData:getRGBA(x,y)
end

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
        self._quad:setRect(-self.width/2, -self.height/2, self.width/2, self.height/2)
    end
    return self._quad
end

function Texture:_getRect()
	local r = Rect(0,0, self.width, self.height)
	return r
end

--[[
pixel collision hitTest between 2 textures

parameters
    p1: bottom left position (vec2) of the texture
    a1: alpha treshold to consider texture1 pixel transparent
    texture2: texture to check collision with
    p2: bottom left position (vec2) of texture2
    a2: alpha treshold to consider texture2 pixel transparent

--]]
function Texture:hitTest(p1,a1,texture2,p2,a2)
    return imageHitTestEx(self.srcData,p1,a1,
        texture2.srcData,p2,a2,
		self:_getRect(),
		texture2:_getRect(),
		self.rotated,
		texture2.rotated)
end
