--[[---
A texture atlas is a collection of many smaller textures in one big 
image. This class is used to access textures from such an atlas. 

Using a texture atlas for your textures solves two problems: avoid 
frequent texture switches and reduce memory consuption

A texture atlas is meant as a single image subdivided into logical 
named regions. Once a atlas is created is possible to add new named 
regions, having a 1:1 between regions and subtextures. It's then 
possible to query for single named texure, or for a group of sorted
texture that share a prefix in the name.
--]]

TextureAtlas = class()

--enum internally used for region structure rapresentation
local REGION_RECT 		= 1
local REGION_ROTATION 	= 2
local REGION_FRAME 		= 3

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
@tparam int regionWidth width of a single tile
@tparam int regionHeight height of single tile
@tparam[opt=0] int margin num of pixel on the boundary of the texture 
@tparam[opt=0] int spacing num of pixel between tiles
@tparam[opt="image_"] string prefix the prefix name to be applied to each subtexture
@tparam[opt=0] int padding number of ciphers to be used to enumerate subtextures (->%00d
@treturn TextureAtlas
--]]
function TextureAtlas.fromTexture(texture,regionWidth,regionHeight,
            margin,spacing,prefix,padding)
	
    local texture = type(texture) == "string" and Texture.fromFile(texture) or texture
	
	local atlas = TextureAtlas(texture)
	
	--default values
	local margin = margin or 0
	local spacing = spacing or 0
	local padding = padding or 0
	local prefix = prefix or "image_"
	local _format = prefix.."%0"..tostring(padding).."d"
   
    --remove margin left/right and add 1 spacing value, because
    --num of spacing is numOfTiles-1, so adding one spacing value
    --allows to divide for (regionAidth+spacing) to find out
    --exact num of tiles
	local numX = (texture:getWidth() - margin*2 + spacing) / 
        (regionWidth+spacing)
        
	local numY = (texture:getHeight() - margin*2 + spacing) / 
        (regionHeight+spacing)
    
	local w = regionWidth
	local h = regionHeight
	local sw = spacing
	local sh = spacing
	local mw = margin
	local mh = margin
    
    local counter = 1
    for j = 1,numY do
        for i = 1,numX do
            --each region start after one margin plus n*(tile+spacing)
            local region = Rect(mw+(i-1)*(w+sw),mh+(numY-j)*(h+sh),w,h)
			region.y = texture:getHeight() - (region.y + region.h) 
            local frameName = string.format(_format,counter)
            atlas:addRegion(frameName,region)
            counter = counter + 1
        end
    end
    return atlas
end

---A texture atlas is always built over a texture
function TextureAtlas:init(texture)
    self.baseTexture = texture
    self.regions = {}
end

--[[---
Clear inner structs. It's possible to specify if to dispose also the base texture
@tparam[opt=false] bool disposeBaseTexture
--]]
function TextureAtlas:dispose(disposeBaseTexture)
	disposeBaseTexture = disposeBaseTexture == true
	if disposeBaseTexture then 
		self.baseTexture:dispose()
	end
	self.baseTexture = nil
	table.clear(self.regions)
end


--[[---
Add a new named region.
Named regions are uv map rect, so x,y,w,h are in the range [0,1]
@tparam string name the name of the new region
@tparam Rect rect a rect with uvmap values [0,1]
@tparam[opt=false] bool rotated if the region is 90° clockwise rotated
@param frame (optional) if the texture is trimmed frame must be provided
--]]
function TextureAtlas:addRegion(name,rect,rotated,frame)
	if self.regions[name] then
		error("region "..region.." already added to Atlas")
	end
	local newRegion = {}
	newRegion[REGION_RECT] = rect
	newRegion[REGION_ROTATION] = rotated == true
	newRegion[REGION_FRAME] = frame
	self.regions[name] = newRegion
end

--[[---
Returns all the regions sorted by name that begins with "prefix". 
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
Returns the number of textures/regions that begin with prefix.
If no prefix is provided it returns the number of all textures.
@tparam[opt=nil] string prefix prefix to filter region/texture names
@treturn int number of matching textures/regions
--]]
function TextureAtlas:getNumOfTextures(prefix)
	return #self:getSortedNames(prefix)
end


--[[---
Returns a subtexture that wrap a specific named region
@tparam string name the name of the region to use to build the sub texture
@treturn SubTexture.
--]]
function TextureAtlas:getTexture(name)
	local txt = nil
	local region = self.regions[name]
	if region then
			txt = Texture.fromTexture(self.baseTexture, region[REGION_RECT], region[REGION_ROTATION], region[REGION_FRAME])
	end
    return txt
end


--[[---
Returns all the textures sorted by region name, that begin with "prefix". 
If no prefix is provided it returns all the textures.
@param prefix optional, prefix to select region names
@return list of textures
--]]
function TextureAtlas:getTextures(prefix) 
    local textures = {}
	
    local sortedRegions = self:getSortedNames(prefix)
 
    for i,v in ipairs(sortedRegions) do
        table.insert(textures, self:getTexture(v))
    end
    return textures  
end
