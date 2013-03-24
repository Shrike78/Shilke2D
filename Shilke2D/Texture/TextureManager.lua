--[[---
TextureManager allows to mount a texture atlas as a logical resource path.
That means that calling TextureManager.getTexture() makes transparent the load
of a real texture or of a subtexture of a texture atlas.

That allows to create code that doesn't depend on how data is packed.
A use case is to always call TextureManager.getTexture() and, depending on how 
data is packed, add only at initialization phase a list of 
TextureManager.mountAtlas calls.

This list of atlas resources could be moreover defined by external data
--]]
TextureManager = {}

---used to store all the mounted textureAtlases
local __atlasResources = {}
---used to cache the textures stored into the TextureAtlases
local __textureCache = {}

--[[---
Mount a texture atlas as logica resource at a specific path.
It's possible to mount the same atlas at different paths.
It's possible to mount multiple atlas at same path.
@param mountDir the path where to mount the atlas
@param atlas the texture atlas to be mounted
--]]
function TextureManager.mountAtlas(mountDir, atlas)
	local mountDir = IO.getAbsolutePath(mountDir)
	mountDir = (mountDir .. "/"):gsub("//","/") 
	if not __atlasResources[mountDir] then
		__atlasResources[mountDir] = {}
	end
	__atlasResources[mountDir][atlas] = atlas
end

--[[---
Unmount an atlas from given path
@param mountDir the path where to unmount the atlas
@param atlas the texture atlas to be unmounted
--]]
function TextureManager.unmountAtlas(mountDir, atlas)
	local mountDir = IO.getAbsolutePath(mountDir)
	mountDir = (mountDir .. "/"):gsub("//","/") 
	if __atlasResources[mountDir] then
		__atlasResources[mountDir][atlas] = nil
	end
end

--[[---
Returns a texture given a fileName. The texture can be a physical resource or a subtexture
obtained from a texture atlas.
Textures not stored in mounted atlas are loaded through Assets.getText internal call
@param fileName name of the texture to be retrieved
@param useCache if defined override default Assets.__defaultCacheTexture value
--]]
function TextureManager.getTexture(fileName,useCache)
	--work only with absolute paths
	local fileName = IO.getAbsolutePath(fileName)
	
	local useCache = useCache ~= nil and useCache or Assets.__defaultCacheTexture
	
	if __textureCache[fileName] then
		return __textureCache[fileName]
	end
	
	for k,v in pairs(__atlasResources) do 
		if string.starts(fileName,k) then
			local innerName = string.removePrefix(fileName,k)
			for _, atlas in pairs(v) do
				local txt = atlas:getTexture(innerName)
				if txt then
					if useCache then
						__textureCache[fileName] = txt
					end
					return txt
				end
			end
		end
	end
	
	local txt = Assets.getTexture(fileName, useCache)
	return txt
end

--[[---
Remove a texture from the cache. If texture is nil, clears the whole texture cache.
It calls also Assets.clearCache method
@param texture texture path or concrete resource to be removed from cache. 
If nil the whole cache is cleared
--]]
function TextureManager.clearCache(texture)
	if texture then
		if type(texture) == 'string' then
			local cacheName = IO.getAbsolutePath(texture:gsub("\\","/"))
			if __textureCache[cacheName] then 
				__textureCache[cacheName]:dispose()
				__textureCache[cacheName] = nil
				return
			end
		else
			for k,v in pairs(__textureCache) do
				if v == texture then
					--TODO: is it correct to dispose in this situation?
					v:dispose()
					__textureCache[k] = nil
					return
				end
			end
		end
		-- if not returned try to clear from Assets
		Assets.clearTextureCache(texture)
	else
		for _,v in pairs(__textureCache) do
			v:dispose()
		end
		table.clear(__textureCache)
		Assets.clearTextureCache()
	end
end

