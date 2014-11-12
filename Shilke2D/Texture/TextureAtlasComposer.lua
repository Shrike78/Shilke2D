--[[---
TextureAtlasComposer implements ITextureAtlas and allows to work with different atlas textures
without caring about how textures are grouped together.
It's possible in this way to use logical atlas where texture are larger than 
Texture.MAX_WIDTH * Texture.MAX_HEIGHT
--]]

TextureAtlasComposer = class(nil, ITextureAtlas)

function TextureAtlasComposer:init()
	self.atlases = {}
end

---Clears inner structs and disposes all the added atlas
function TextureAtlasComposer:dispose()
	self:clear(true)
end

--[[---
Adds a new atlas
@tparam ITextureAtlas atlas the atlas to be added
@tparam[opt=true] bool ownership
@treturn bool success. Doesn't add the same atlas twice
--]]
function TextureAtlasComposer:addAtlas(atlas)
	local ownership = ownership ~= false
	if table.find(self.atlases, atlas) == 0 then
		self.atlases[#self.atlases+1] = atlas
		return true
	end
	return false
end

--[[---
Removes the atlas from the list of composed atlases
@tparam ITextureAtlas atlas the atlas to remove
@treturn ITextureAtlas the removed atlas. nil if not present
--]]
function TextureAtlasComposer:removeAtlas(atlas)
	return table.removeObj(self.atlases, atlas)
end

--[[---
Removes all the atlas and optionally dispose them
@tparam[opt=false] bool dispose if to dispose or not removed atlases
--]]
function TextureAtlasComposer:clear(dispose)
	if dispose then
		for _,atlas in ipairs(self.atlases) do
			atlas:dispose()
		end
	end
	table.clear(self.atlases)
end

--[[---
Returns all the regions sorted by name, that begin with "prefix". 
If no prefix is provided it returns all the regions
@param prefix optional, prefix to select region names
@return list of regions
--]]
function TextureAtlasComposer:getSortedNames(prefix)
    local sortedRegions = {}
	for _,atlas in ipairs(self.atlases) do
		table.extend(sortedRegions, atlas:getSortedNames(prefix))
	end
	table.sort(sortedRegions)
    return sortedRegions
end


--if "name" is a registered named region, it get the referenced atlas
--and returns the subtexture
function TextureAtlasComposer:getTexture(name)
	for _,atlas in ipairs(self.atlases) do
		local t = atlas:getTexture(name)
		if t then
			return t
		end
	end
    return nil
end
