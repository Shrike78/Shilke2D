-- BigTextureAtlas

--[[
BigTextureAtlas allows to work with different atlas textures
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

--add a new atlas and register all the named rects of the
--new atlas. if double name is found it raise an error
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

--remove the atlas from big atlas and clear all the named region 
--of the removed atlas
function BigTextureAtlas:removeAtlas(atlas)
    for i,v in pairs(self.regionMap) do
        if v == atlas then
            regionMap[i] = nil
        end
    end
end

--BigTextureAtlas accept only other atlas, it's not
--possible to directly add new named regions
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

--if no prefix is provided it returns all the names
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

--if no prefix is provided it returns all the textures
function BigTextureAtlas:getTextures(prefix) 
    local textures = {}
    
    local sortedRegions = self:getSortedNames(prefix)
 
    for _,v in ipairs(sortedRegions) do
        table.insert(textures, self.regionMap[v]:getTexture(v))
    end
    return textures  
end