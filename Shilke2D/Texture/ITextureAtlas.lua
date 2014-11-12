--[[---
Interface for TextureAtlas classes.
A texture atlas class must provide methdods to iterate over texture regions
--]]

ITextureAtlas = class()

--[[---
Returns all the regions sorted by name that begins with a given prefix.
If no prefix is provided it returns all the regions.
@tparam[opt=nil] string prefix prefix to filter region names
@treturn {string}
--]]
function ITextureAtlas:getSortedNames(prefix)
	error("method must be overridden")
end


--[[---
Returns the number of textures/regions that begin with a given prefix.
If no prefix is provided it returns the number of all the textures.
@tparam[opt=nil] string prefix prefix to filter region/texture names
@treturn int number of matching textures/regions
--]]
function ITextureAtlas:getNumOfTextures(prefix)
	return #self:getSortedNames(prefix)
end


--[[---
Returns a subtexture that wrap a specific named region.
@tparam string name the name of the region to use to build the sub texture
@treturn SubTexture.
--]]
function ITextureAtlas:getTexture(name)
	error("method must be overridden")
end


--[[---
Returns all the textures sorted by region name, that begin with a given prefix. 
If no prefix is provided it returns all the textures.
@tparam[opt=nil] string prefix prefix to select region names
@treturn {SubTexture}
--]]
function ITextureAtlas:getTextures(prefix) 
	local sortedRegions = self:getSortedNames(prefix)	
	local textures = {}
	for i,name in ipairs(sortedRegions) do
		textures[i] = self:getTexture(name)
	end
	return textures  
end


