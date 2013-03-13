-- TextureAtlas

--[[
A texture atlas is a collection of many smaller textures in one big 
image. This class is used to access textures from such an atlas. 

Using a texture atlas for your textures solves two problems: avoid 
frequent texture switches and reduce memory consuption because not
power of 2 images waste memory once loaded, and a well formed
texture atlas may reduce the problem

A texture atlas is meant as a single image subdivided into logical 
named regions. Once a atlas is created is possible to add new named 
regions, having a 1:1 between regions and subtextures. It's then 
possible to queru for single named texure, or for a group of sorted
texture that share a prefix in the name.
--]]

TextureAtlas = class()

--[[
automatic creation of a tilest starting from a texture, where all 
the regions have the same size, are packed sequentially and have
no hole in the middle of the sequence.

- regionWidth,regionHeight: size of single tile

- margin: num of pixel on the boundary of the texture 

- spacing: num of pixel between tiles

The name of each regions will be in the form of prefix%0'padding'd, 
where padding is optional. if not provided there will be no padding.

ie: padding 3 will produce a sequence like:
prefix001
prefix002
prefix003
[..]
--]]
function TextureAtlas.fromTexture(texture,regionWidth,regionHeight,
            margin,spacing,prefix,padding)
            
    local atlas = TextureAtlas(texture)
    
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
    
    local padding = padding or "0"
    local format = prefix.."%0"..padding.."d"
    local counter = 1
    for j = 1,numY do
        for i = 1,numX do
            --each region start after one margin plus n*(tile+spacing)
            local region = Rect(mw+(i-1)*(w+sw),mh+(numY-j)*(h+sh),w,h)
			region.y = 1 - (region.y+region.h) 
            local frameName = string.format(format,counter)
            atlas:addRegion(frameName,region)
            counter = counter + 1
        end
    end
    return atlas
end

function TextureAtlas:init(texture)
    --[[
    assert(texture:is_a(Texture))
    assert(not(texture:is_a(SubTexture)), 
        "SebTexture of Subtexture is not supported at now")
    --]]
    self.baseTexture = texture
    self.regions = {}
end

function TextureAtlas:dispose()
	if self.baseTexture then self.baseTexture:dispose() end
	table.clear(self.regions)
end

--named region are uv map rect, so x,y,w,h are in the range [0..1]
function TextureAtlas:addRegion(name,rect)
    --assert(rect:is_a(Rect))
    self.regions[name] = rect
end

--return a subtexture that wrap a specific named region
function TextureAtlas:getTexture(name)
    local region = self.regions[name]
    if region then
        return SubTexture(self.baseTexture,region)
    end
    return nil
end

--if no prefix is provided it returns all the sorted regions name
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

--if no prefix is provided it returns all the subtextures sorted 
--by name
function TextureAtlas:getTextures(prefix) 
    local textures = {}
    
    local sortedRegions = self:getSortedNames(prefix)
 
    for i,v in ipairs(sortedRegions) do
        table.insert(textures,
            Texture.fromTexture(self.baseTexture,self.regions[v]))
    end
    return textures  
end