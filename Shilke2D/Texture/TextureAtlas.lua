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
is loaded using Assets.getTexture function, using defaul cache logic
@param regionWidth width of a single tile
@param regionHeight height of single tile
@param margin num of pixel on the boundary of the texture 
@param spacing num of pixel between tiles
@param prefix the prefix name to be applied to each subtexture
@param padding number of ciphers to be used to enumerate subtextures
@return TextureAtlas
--]]
function TextureAtlas.fromTexture(texture,regionWidth,regionHeight,
            margin,spacing,prefix,padding)
	
    local texture = type(texture) == "string" and Assets.getTexture(texture) or texture
	
	local atlas = TextureAtlas(texture)
	
	--default values
	local margin = margin or 0
	local spacing = spacing or 0
	local padding = padding or "0"
	local prefix = prefix or "image_"
	local _format = prefix.."%0"..padding.."d"
   
    --remove margin left/right and add 1 spacing value, because
    --num of spacing is numOfTiles-1, so adding one spacing value
    --allows to divide for (regionAidth+spacing) to find out
    --exact num of tiles
    local numX = (texture.width - margin*2 + spacing) / 
        (regionWidth+spacing)
        
    local numY = (texture.height - margin*2 + spacing) / 
        (regionHeight+spacing)
    
    --translate all positional infos to percentage in [0..1]
    --range (region are UV map over base texture)
    local w = regionWidth / texture.width
    local h = regionHeight / texture.height
    local sw = spacing / texture.width
    local sh = spacing / texture.height
    local mw = margin / texture.width
    local mh = margin / texture.height
    
    local counter = 1
    for j = 1,numY do
        for i = 1,numX do
            --each region start after one margin plus n*(tile+spacing)
            local region = Rect(mw+(i-1)*(w+sw),mh+(numY-j)*(h+sh),w,h)
			region.y = 1 - (region.y+region.h) 
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

---Dispose also the texture is using as atlas
function TextureAtlas:dispose()
	if self.baseTexture then 
		self.baseTexture:dispose() 
	end
	table.clear(self.regions)
end


--[[---
Add a new named region.
Named regions are uv map rect, so x,y,w,h are in the range [0,1]
@param name the name of the new region
@param rect a rect with uvmap values [0,1]
--]]
function TextureAtlas:addRegion(name,rect)
    self.regions[name] = rect
end

---Returns a subtexture that wrap a specific named region
--@param name the name of the region to use to build the sub texture
--@return SubTexture. nil if the region name doesn't belong to current atlas
function TextureAtlas:getTexture(name)
    local region = self.regions[name]
    if region then
        return SubTexture(self.baseTexture,region)
    end
    return nil
end

--[[---
Returns all the regions sorted by name, that begin with "prefix". 
If no prefix is provided it returns all the regions
@param prefix optional, prefix to select region names
@return list of regions
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
Returns all the textures sorted by region name, that begin with "prefix". 
If no prefix is provided it returns all the textures.
@param prefix optional, prefix to select region names
@return list of textures
--]]
function TextureAtlas:getTextures(prefix) 
    local textures = {}
	
    local sortedRegions = self:getSortedNames(prefix)
 
    for i,v in ipairs(sortedRegions) do
        table.insert(textures,
            Texture.fromTexture(self.baseTexture,self.regions[v]))
    end
    return textures  
end
