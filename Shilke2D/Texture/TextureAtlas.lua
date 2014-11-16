--[[---
A texture atlas is a collection of many smaller textures in one big 
texture. This class is used to access textures from such an atlas. 

Using a texture atlas for your textures solves two problems: avoid 
frequent texture switches and reduce memory consuption

A texture atlas is meant as a single image subdivided into logical 
named regions. Once a atlas is created is possible to add new named 
regions, having a 1:1 between regions and subtextures. It's then 
possible to query for single named texure, or for a group of sorted
texture that share a prefix in the name.
--]]

TextureAtlas = class(nil, ITextureAtlas)

--[[---
Automatic creation of a tilest starting from a texture, where all 
the regions have the same size, are packed sequentially and have
no hole in the middle of the sequence.

The name of each regions will be in the form of prefix%0'padding'd, 
where padding is optional. if not provided there will be no padding.

ie: padding 3 will produce a sequence like:
prefix001
prefix002
prefix003

@param texture can be a Texture or a path, in that case the texture 
is loaded using Texure.fromFile function using default color transformation
@tparam int w width of a single tile
@tparam int h height of single tile
@tparam[opt=0] int margin num of pixel on the boundary of the texture 
@tparam[opt=0] int spacing num of pixel between tiles
@tparam[opt="image_"] string prefix the prefix name to be applied to each subtexture
@tparam[opt=0] int padding number of ciphers to be used to enumerate subtextures (->%00d
@tparam[opt=".png"] string ext extension to be applied to each subtexture. If texture is 
proived as filename it override this value using the same extension of source image
@treturn TextureAtlas
--]]
function TextureAtlas.fromTexture(texture,w,h,margin,spacing,prefix,padding, ext)
	
	--default values
	local margin = margin or 0
	local spacing = spacing or 0
	local padding = padding or 0
	local prefix = prefix or "image_"
	local _format = prefix.."%0"..tostring(padding).."d%s"
	local ext = ext or ".png"
    local texture = texture
	if type(texture) == "string" then
		ext = "." .. string.getFileExtension(texture)
		texture = Texture.fromFile(texture)
	end
	
	local atlas = TextureAtlas(texture)
	
	local tw, th = texture:getSize()
    --remove margin left/right and add 1 spacing value, because
    --num of spacing is numOfTiles-1, so adding one spacing value
    --allows to divide for (regionAidth+spacing) to find out
    --exact num of tiles
	local numX = (tw - margin*2 + spacing) / (w+spacing)
	local numY = (th - margin*2 + spacing) / (h+spacing)
	--same spacing / margin fot both directions
	local sw, sh = spacing, spacing
	local mw, mh = margin, margin
    local region = Rect()
	
    local counter = 1
    for j = 1,numY do
        for i = 1,numX do
            --each region start after one margin plus n*(tile+spacing)
            region:set(mw+(i-1)*(w+sw), mh+(numY-j)*(h+sh), w, h)
			region.y = th - (region.y + region.h) 
            local frameName = string.format(_format,counter,ext)
            atlas:addRegion(frameName,region)
            counter = counter + 1
        end
    end
    return atlas
end

--[[---
A texture atlas is always built over a texture
@tparam Texture texture the base texture of the atlas.
--]]
function TextureAtlas:init(texture)
    self.baseTexture = texture
    self.regions = {}
end


--[[---
Clears inner structs and disposes the base texture and all the created subtextures, 
so take care of not having textures in use after disposing it.
--]]
function TextureAtlas:dispose()
	self.baseTexture:dispose()
	self.baseTexture = nil
	self:clearRegions()
end


--[[---
returns the base texture on wich the atlas is built
@treturn Texture
--]]
function TextureAtlas:getBaseTexture()
	return self.baseTexture
end


--[[---
Add a new named region.
@function TextureAtlas:addRegion
@tparam string name the name of the new region
@tparam BitmapRegion region
--]]

--[[---
Add a new named region.
@tparam string name the name of the new region
@tparam Rect region a rect over the base texture
@tparam[opt=false] bool rotated if the region is 90° clockwise rotated
@param frame (optional) if the texture is trimmed frame must be provided
@treturn bool success doesn't add the same named region twice
--]]
function TextureAtlas:addRegion(name,region,rotated,frame)
	if self.regions[name] then
		return false
	end
	self.regions[name] = Texture.fromTexture(self.baseTexture,region,rotated,frame)
	return true
end

--[[---
Remove a region from the texture atlas. The related subtexure is disposed
@tparam string name
@treturn bool success
--]]
function TextureAtlas:removeRegion(name)
	local t = self.regions[name]
	if not t then
		return false
	end
	t:dispose()
	self.regions[name] = nil
	return true
end

---Removes and disposes all the created subtextures.
function TextureAtlas:clearRegions()
	for _,r in pairs(self.regions) do
		r:dispose()
	end
	table.clear(self.regions)
end

--[[---
Returns all the regions sorted by name that begins with a given prefix. 
If no prefix is provided it returns all the regions.
@tparam[opt=nil] string prefix prefix to filter region names
@treturn {string}
--]]
function TextureAtlas:getSortedNames(prefix)
    local sortedRegions = {}
    if prefix then
        for n,_ in pairs(self.regions) do
            local idx = string.find(n,prefix)
            if idx == 1 then
                sortedRegions[#sortedRegions + 1] = n
            end
        end    
    else
        for n,_ in pairs(self.regions) do
            sortedRegions[#sortedRegions + 1] = n
        end
    end
    table.sort(sortedRegions)
	return sortedRegions
end


--[[---
Returns a subtexture that wrap a specific named region
@tparam string name the name of the region to use to build the sub texture
@treturn SubTexture.
--]]
function TextureAtlas:getTexture(name)
	return self.regions[name]
end

