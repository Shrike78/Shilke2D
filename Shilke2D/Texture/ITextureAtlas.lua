--[[---
Interface for TextureAtlas classes.
A texture atlas class must provide methdods to iterate over texture list.
--]]

ITextureAtlas = class()

--[[---
Returns all the texture names that begin with "prefix", sorted alphabetically.  
If no prefix is provided it returns all the names
@param prefix optional, prefix to select texture names
@return list list of texture names
--]]
function ITextureAtlas:getSortedNames(prefix)
	error("method must be overridden")
end

--[[---
Returns the number of textures with a name that starts with prefix.
If no prefix is provided it returns the number of all the textures.
@param prefix optional, prefix to select region/texture names
@return number number of textures that match prefix
--]]
function ITextureAtlas:getNumOfTextures(prefix)
	--Basic implementation. optimized override should be implemented in concrete texture atlas classes
	return #self:getSortedNames(prefix)
end

---Returns a texture with a given name
--@param name the name of the texture
--@return Texture the texture with the given name. nil if the name doesn't belong to current atlas
function ITextureAtlas:getTexture(name)
	error("method must be overridden")
end


--[[---
Returns all the textures that begin with "prefix", sorted alphabetically. 
If no prefix is provided it returns all the textures.
@param prefix optional, prefix to select region names
@return list of textures
--]]
function ITextureAtlas:getTextures(prefix) 
	local sortedRegions = self:getSortedNames(prefix)	
	local textures = {}
	for i,v in ipairs(sortedRegions) do
		textures[i] = self:getTexture(v)
	end
	return textures  
end


