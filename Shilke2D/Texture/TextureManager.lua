--[[---
Texture Manager is an helper namespace to work with textures.

It's a sort of file system wrapper for textures: it allows to register
textures and mount atlases as virtual directories.

All the required textures are cached in order to share memory and reduce 
load time.
--]]
TextureManager = {}

local __textures = {}
local __atlases  = {}
local __atlasesCache = {}

--[[---
Clear inner structs.
@tparam[opt=true] bool disposeTextures if true all the cached textures are also
disposed
@tparam[opt=true] bool disposeAtlases if true all the mounted atlases are also
disposed
--]]
function TextureManager.clear(disposeTextures, disposeAtlases)
	local disposeTextures 	= disposeTextures ~= false
	local disposeAtlases 	= disposeAtlases ~= false
	
	if disposeTextures then
		for _,t in pairs(__textures) do
			t:dispose()
		end
	end
	if disposeAtlases then
		for _,atlas in pairs(__atlases) do
			atlas:dispose()
		end
	end
	table.clear(__textures)
	table.clear(__atlases)
	table.clear(__atlasesCache)
end


--[[---
Register a texture with a given name
@function TextureManager.addTexture
@tparam string name the name (path) used to register the texture
@tparam Texture texture
@treturn bool success
--]]


--[[---
Register a texture with a given name
@tparam string name the name (path) used to register the texture
@tparam string texture filename of the texture to load
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions
@treturn bool success
--]]
function TextureManager.addTexture(name, texture, transformOptions)
	local registerdName = IO.getAbsolutePath(name)
	if not __textures[registerdName] then
		local texture = texture
		if type(texture) == 'string' then
			texture = Texture.fromFile(texture, transformOptions)
		end
		__textures[registerdName] = texture
		return true
	end
	return false
end


--[[---
remove a given texture from cache
@tparam string name the name of the texture to remove. it doesn't work on
atlas textures
@tparam[opt=true] bool if the removed texture must be disposed
@treturn bool success
--]]
function TextureManager.removeTexture(name, dispose)
	local txt = __textures[name]
	local dispose = dispose ~= false
	if txt then
		__textures[name] = nil
		if txt and dispose then
			txt:dispose()
		end
		return true
	end
	return false
end


--[[---
Mounts a texture atlas as logical resource at a specific path.
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
	if __atlases[mountDir] then
		return false
	end
	__atlases[mountDir] = atlas
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
	local atlas = __atlases[mountDir]
	if atlas then
		__atlases[mountDir] = nil
		for k,_ in pairs(__atlasesCache) do
			if string.starts(k, mountDir) then
				__atlasesCache[k] = nil
			end
		end
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
	for k,_ in pairs(__atlases) do
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
	return __atlases[mountDir]
end


--[[---
Returns a texture based on name. If the texture is not registered
it can load and automatically register as new resource
@tparam string name the name of the texure to return
@tparam[opt=true] bool addIfAbsent if the name is not registered, 
if addIfAbsent is true the texture is loaded and registerd, else return nil
@treturn[1] Texture
@return[2] nil
@treturn[2] string error message
--]]
function TextureManager.getTexture(name, addIfAbsent)
	local fileName = IO.getAbsolutePath(name)
	local addIfAbsent = addIfAbsent~=false
	local err = nil
	--check if one of the cached textures
	local txt = __textures[fileName]
	--check in atlas cache 
	if not txt then
		txt = __atlasesCache[fileName]
	end
	--check in all the atlases 
	if not txt then
		for mountDir,atlas in pairs(__atlases) do 
			if string.starts(fileName, mountDir) then
				local innerName = string.removePrefix(fileName, mountDir)
				txt = atlas:getTexture(innerName)
				__atlasesCache[fileName] = txt
				break
			end
		end
	end
	--if not already registered and addIfAbsent is true, 
	--loads a new texture with default transformOptions
	if not txt and addIfAbsent then
		txt, err = Texture.fromFile(fileName)
		__textures[fileName] = txt
	end
	return txt, err
end



