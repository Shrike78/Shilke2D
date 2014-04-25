--[[---
TextureAtlasComposer implements ITextureAtlas and allows to work with different atlas textures
without caring about how textures are grouped together.
It's possible in this way to use logical atlas where texture are larger
than 2048x2048 
--]]

TextureAtlasComposer = class(nil, ITextureAtlas)

function TextureAtlasComposer:init()
    --store atlas reference for each region index
    self.regionMap = {}
end

function TextureAtlasComposer:dispose()
	--avoid to call twice dispose on same sub atlas
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
function TextureAtlasComposer:addAtlas(atlas)
    local sortedNames = atlas:getSortedNames()
    for _,region in ipairs(sortedNames) do
        if self.regionMap[region] then
            error("region "..region.." already added")
        else
            self.regionMap[region] = atlas
        end
    end
end

--[[---
Removes the atlas and clears all the named region 
of the removed atlas
@param atlas TextureAtlas to be removed
--]]
function TextureAtlasComposer:removeAtlas(atlas)
    for i,v in pairs(self.regionMap) do
        if v == atlas then
            regionMap[i] = nil
        end
    end
end


--[[---
Returns all the regions sorted by name, that begin with "prefix". 
If no prefix is provided it returns all the regions
@param prefix optional, prefix to select region names
@return list of regions
--]]
function TextureAtlasComposer:getSortedNames(prefix)
    local sortedRegions = {}
	for n,_ in pairs(self.regionMap) do
		if not prefix or string.starts(n,prefix) then
			sortedRegions[#sortedRegions + 1] = n
		end
	end    
    table.sort(sortedRegions)
    return sortedRegions
end

--[[---
Returns the number of textures with a name that starts with prefix.
If no prefix is provided it returns the number of all the textures.
@param prefix optional, prefix to select region/texture names
@return number number of textures that match prefix
--]]
function TextureAtlasComposer:getNumOfTextures(prefix)
	local res = 0
	for n,_ in pairs(self.regions) do
		if not prefix or string.starts(n,prefix) then
			res = res + 1
		end
	end    
	return res
end


--if "name" is a registered named region, it get the referneced atlas
--and returns the subtexture
function TextureAtlasComposer:getTexture(name)
    local atlas = self.regionMap[name]
    if atlas then
        return atlas:getTexture(name)
    end
    return nil
end

