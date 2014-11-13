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
@treturn Texture nil if the provided name was not registered
--]]
function TextureManager.removeTexture(name)
	local txt = __textures[name]
	if txt then
		__textures[name] = nil
	end
	return txt
end


--[[---
Mounts a texture atlas as logical resource at a specific path.
<ul>
<li>It's possible to mount the same atlas at different paths</li>
<li>It's possible to override a physical path with mount points</li>
<li>Only one atlas can be mount at one mount point</li>
</ul>
@tparam string mountDir the path where to mount the atlas
@tparam ITextureAtlas atlas the texture atlas to be mounted
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
@treturn ITextureAtlas the removed atlas (nil if the provided mountDir was not valid)
--]]
function TextureManager.unmountAtlas(mountDir)
	local mountDir = IO.getAbsolutePath(mountDir)
	mountDir = (mountDir .. "/"):gsub("//","/") 
	local atlas = __atlases[mountDir]
	if atlas then
		__atlases[mountDir] = nil
	end
	return atlas
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
@tparam[opt=true] bool autoRegister if the name is not registered and
autoRegister is true, the texture is loaded and registered, else returns nil
@treturn[1] Texture
@return[2] nil
@treturn[2] string error message
--]]
function TextureManager.getTexture(name, autoRegister)
	local fileName = IO.getAbsolutePath(name)
	local autoRegister = autoRegister~=false
	local err = nil
	--check if one of the cached textures
	local txt = __textures[fileName]
	--check in all the atlases 
	if not txt then
		for mountDir,atlas in pairs(__atlases) do 
			if string.starts(fileName, mountDir) then
				local innerName = string.removePrefix(fileName, mountDir)
				txt = atlas:getTexture(innerName)
				break
			end
		end
	end
	--if not already registered and addIfAbsent is true, 
	--loads a new texture with default transformOptions
	if not txt and autoRegister then
		txt, err = Texture.fromFile(fileName)
		if txt then
			__textures[fileName] = txt
		end
	end
	return txt, err
end


--[[---
Returns all the registered textures that matches the given prefix, sorted alphabetically. 
If no prefix is provided it returns all the registered texture names.
@string[opt=nil] prefix
@treturn {string} sorted names
--]]
function TextureManager.getRegisteredNames(prefix)
	if prefix then
		prefix = IO.getAbsolutePath(prefix)
	end
	local res = {}
	for k,_ in pairs(__textures) do
		if not prefix or string.starts(k, prefix) then
			res[#res+1] = k
		end
	end
	
	for k,v in pairs(__atlases) do
		local names = nil
		if not prefix or string.starts(k, prefix) then
			names = v:getSortedNames()
		elseif string.starts(prefix, k) then
			local prefix = prefix:sub(k:len()+1)
			names = v:getSortedNames(prefix)
		end
		if names then
			for _,name in ipairs(names) do
				res[#res+1] = k .. name
			end
		end
	end
	table.sort(res)
	return res
end


--[[---
Returns all the registered textures that matches the given prefix, sorted alphabetically.
If no prefix is provided returns all the registered textures.
@string[opt=nil] prefix
@treturn {Texture}
--]]
function TextureManager.getTextures(prefix)
	local regionNames = TextureManager.getRegisteredNames(prefix)
	local res = {}
	for _,name in ipairs(regionNames) do
		res[#res+1] = TextureManager.getTexture(name)
	end
	return res
end

