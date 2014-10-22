--[[---
TextureManager allows to mount a texture atlas as a logical resource path.
That means that calling TextureManager.getTexture() makes transparent the load
of a real texture or of a subtexture of a texture atlas.

That allows to create code that doesn't depend on how data is packed.

That's usefull moving from development/debug to release, where textures of a specific
path may be packed only for release version but the code for loading assets can be left 
unchanged, except for the initialization mount phase.

TextureManager also allows to optionally cache the loaded textures. Default behaviour is 
to always cache resources but it can be changed for application execution changing the 
__defaultCacheTexture attribute of texture manager.
--]]
TextureManager = {}

---used to store all the mounted textureAtlases
local __atlasResources = {}

---used to cache the textures loaded from filesystem. dictionary of dictionary (sorted for
--'colorTransform' value
local __textureCache = {}
---used to cache the textures stored into the TextureAtlases
local __textureCacheAtlas = {}

---default behaviour for caching. change it to invert default behavior for the application
TextureManager.__defaultCacheTexture = true

---default behaviour for getTexture priority search: default is firt check virtual mount points, 
--then physical paths. Set to false to invert the behaviour
TextureManager.__priorityMountPointFirst = true


--[[---
Mount a texture atlas as logica resource at a specific path.
<ul>
<li>It's possible to mount the same atlas at different paths</li>
<li>It's possible to override a physical path with mount points</li>
<li>Only one atlas can be mount at one mount point</li>
</ul>
@tparam string mountDir the path where to mount the atlas
@tparam TextureAtlas atlas the texture atlas to be mounted
@treturn bool success
--]]
function TextureManager.mountAtlas(mountDir, atlas)
	local mountDir = IO.getAbsolutePath(mountDir)
	mountDir = (mountDir .. "/"):gsub("//","/")
	if __atlasResources[mountDir] then
		return false
	end
	__atlasResources[mountDir] = atlas
	return true		
end

--[[---
Unmount an atlas from given path
@tparam string mountDir the path where to unmount the atlas
@tparam[opt=false] bool dispose if to dispose or not the released textures
@treturn bool success
--]]
function TextureManager.unmountAtlas(mountDir, dispose)
	local mountDir = IO.getAbsolutePath(mountDir)
	local dispose = dispose == true
	mountDir = (mountDir .. "/"):gsub("//","/") 
	local atlas = __atlasResources[mountDir]
	if atlas then
		for _,textureName in atlas:getSortedNames() do
			local cacheName = mountDir .. textureName
			self:removeCachedTexture(cacheName,ColorTransform.NONE,dispose)
		end
		__atlasResources[mountDir] = nil
		return true
	end
	return false
end


--[[---
returns a list of all the mounted dirs
@treturn {string}
--]]
function TextureManager.getMountedDirs()
	local res = {}
	for k,_ in pairs(__atlasResources) do
		res[#res+1] = k
	end
	return res
end


--[[---
returns the atlas mounted at specific mountDir
@tparam string mountDir
@treturn TextureAtlas
--]]
function TextureManager.getMountedAtlas(mountDir)
	return __atlasResources[mountDir]
end


--[[---
local function used to retrieve a texture from one of the mounted atlases
@tparam string fileName
@tparam[opt=nil] ColorTransform transformOptions unused, declared just for compatibility
@tparam[opt=__defaultCacheTexture] bool useCache
@treturn SubTexture
--]]
local function getAtlasTexture(fileName, transformOptions, useCache)
	if useCache and __textureCacheAtlas[fileName] then
		return __textureCacheAtlas[fileName]
	end
	for mountDir,atlas in pairs(__atlasResources) do 
		if string.starts(fileName, mountDir) then
			local innerName = string.removePrefix(fileName, mountDir)
			local txt = atlas:getTexture(innerName)
			if txt then
				if useCache then
					__textureCacheAtlas[fileName] = txt
				end
				return txt
			end
		end
	end
	return nil
end


--[[---
local function used to retrieve a texture from one of the mounted atlases
@tparam string fileName
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions 
@tparam[opt=__defaultCacheTexture] bool useCache
@treturn Texture
--]]
local function getPhysicalTexture(fileName, transformOptions, useCache)
	if useCache and __textureCache[transformOptions] and __textureCache[transformOptions][fileName] then
		return __textureCache[transformOptions][fileName]
	end
	local txt = Texture.fromFile(fileName, transformOptions)
	if txt and useCache then
		if not __textureCache[transformOptions] then
			__textureCache[transformOptions] = {}
		end
		__textureCache[transformOptions][fileName] = txt
	end
	return txt
end


--[[---
Returns a texture given a fileName. The texture can be a physical resource or a subtexture
obtained from a texture atlas.
Textures not stored in mounted atlas are loaded through Assets.getTexture
@tparam string fileName name of the texture to be retrieved
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions If the texture is
packed in a atlas the parameter is unused
@tparam[opt=__defaultCacheTexture] bool useCache if cache is used, already retrieved textures are
stored in cache dictionaries, indexed by name and ColorTransform
@treturn[1] Texture
@return[2] nil
@treturn[2] string error message
--]]
function TextureManager.getTexture(fileName, transformOptions, useCache)
	
	local fileName = IO.getAbsolutePath(fileName)
	local transformOptions = transformOptions or ColorTransform.PREMULTIPLY_ALPHA
	
	if useCache == nil then
		useCache = TextureManager.__defaultCacheTexture
	end

	local getFunctions = TextureManager.__priorityMountPointFirst and 
		{getAtlasTexture, 		getPhysicalTexture} or
		{getPhysicalTexture, 	getAtlasTexture}	
	
	local txt = getFunctions[1](fileName, transformOptions, useCache)
	if not txt then
		txt = getFunctions[2](fileName, transformOptions, useCache)
	end
	return txt
end


--[[---
Remove a texture from the cache and return it
@tparam string textureFileName
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions If the texture is
packed in a atlas the parameter is unused
@tparam[opt=false] bool dispose
@treturn Texture
--]]
function TextureManager.removeCachedTexture(textureFileName, transformOptions, dispose)
	local cacheName = IO.getAbsolutePath(textureFileName)
	local transformOptions = transformOptions or ColorTransform.PREMULTIPLY_ALPHA
	local dispose = dispose == true
	if __textureCacheAtlas[cacheName] then 
		if dispose then
			__textureCacheAtlas[cacheName]:dispose()
		end
		__textureCacheAtlas[cacheName] = nil
		return true
	elseif __textureCache[transformOptions] and __textureCache[transformOptions][cacheName] then
		if dispose then
			__textureCache[transformOptions][cacheName]:dispose()
		end
		__textureCache[transformOptions][cacheName] = nil
		return true
	end
	return false
end

--[[---
Clears the whole texture cache.
@tparam[opt=false] bool dispose if the textures must be disposed or not when released from cache
--]]
function TextureManager.clearCache(dispose)
	local dispose = dispose == true
	if dispose then
		for _,v in pairs(__textureCacheAtlas) do
			v:dispose()
		end
		for  _,options in pairs(__textureCache) do
			for _,v in pairs(options) do
				v:dispose()
			end
		end
	end
	table.clear(__textureCacheAtlas)
	table.clear(__textureCache)
end


