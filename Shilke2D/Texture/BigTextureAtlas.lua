--[[---
BigTextureAtlas inherits TextureAtlas and allows to work with different atlas textures
without caring about how textures are grouped together.
It's possible in this way use logical atlas where texture are larger
than 2048x2048 
--]]

BigTextureAtlas = class(TextureAtlas)

function BigTextureAtlas:init()
    --store atlas reference for each region index
    self.regionMap = {}
end

function BigTextureAtlas:dispose()
	local tmp = {}
	for i,v in pairs(self.regionMap) do
		if not tmp[v] then
			v:dispose()
			tmp[v] = v
		end
	end
	table.clear(tmp)
	table.clear(self.regionMap)
end

--[[---
Adds a new atlas and registers all the named rects of the
new atlas. If double name is found it raises an error
@param atlas TextureAtlas to be added
--]]
function BigTextureAtlas:addAtlas(atlas)
    local sortedNames = atlas:getSortedNames()
    for _,region in ipairs(sortedNames) do
        if self.regionMap[region] then
            error("region "..region.." already added to BigAtlas")
        else
            self.regionMap[region] = atlas
        end
    end
end

--[[---
Removes the atlas from big atlas and clears all the named region 
of the removed atlas
@param atlas TextureAtlas to be removed
--]]
function BigTextureAtlas:removeAtlas(atlas)
    for i,v in pairs(self.regionMap) do
        if v == atlas then
            regionMap[i] = nil
        end
    end
end

--[[---
BigTextureAtlas accept only other atlas, it's not
possible to directly add new named regions so if the 
function is called an error is raised
--]]
function BigTextureAtlas:addRegion(name,rect)
    error("BigTextureAtlas do not support adding new regions")
end

--if "name" is a registered named region, it get the referneced atlas
--and returns the subtexture
function BigTextureAtlas:getTexture(name)
    local atlas = self.regionMap[name]
    if atlas then
        return atlas:getTexture(name)
    end
    return nil
end

--[[---
Returns all the regions sorted by name, that begin with "prefix". 
If no prefix is provided it returns all the regions
@param prefix optional, prefix to select region names
@return list of regions
--]]
function BigTextureAtlas:getSortedNames(prefix)
    local sortedRegions = {}
    if prefix then
        for n,_ in pairs(self.regionMap) do
            local idx = string.find(n,prefix)
            if idx == 1 then
                sortedRegions[#sortedRegions + 1] = n
            end
        end    
    else
        for n,_ in pairs(self.regionMap) do
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
function BigTextureAtlas:getTextures(prefix) 
    local textures = {}
    
    local sortedRegions = self:getSortedNames(prefix)
 
    for _,v in ipairs(sortedRegions) do
        table.insert(textures, self.regionMap[v]:getTexture(v))
    end
    return textures  
end
