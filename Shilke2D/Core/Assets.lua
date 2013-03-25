--[[---
Assets namespace provides facilities to load different 
type of resources.
--]]
Assets = {}

local __textureCache = {}

---
-- by default texture are cached. It's possibile to change this value.
Assets.__defaultCacheTexture = true

--[[---
Load a sound.
@param fileName the name of the sound to load, relative to the working dir or absolute (starting with /)
@return a sound object if fileName is a valid path, else nil
@return an error message if fileName is not a valid path
--]]
function Assets.getSound(fileName)
	local sound = Sound()
	if string.starts(fileName,"/") then
		local absFileName = IO.getAbsolutePath(fileName)
		sound:load(IO.__baseDir .. absFileName)
	else
		sound:load(fileName)
	end
	--if the file doesn't exist the getLength method returns nil
	if sound:getLength() == nil then
		return nil, fileName .. " is not a valid path"
	end
	return sound
end


--[[---
Load an Xml.
@param fileName the name of the xml to load, relative to the working dir or absolute (starting with /)
@return an XmlNode if fileName is a valid path, else nil
@return an error message if fileName is not a valid path
--]]
function Assets.getXml(fileName)
	local xmlFile, err = IO.getFile(fileName)
	if not xmlFile then 
		return nil, err
	end
	return XmlNode.fromString(xmlFile)
end


--[[---
Load a raw image.
@param fileName the name of the raw image to load, relative to the working dir or absolute (starting with /)
@return a MOAIImage if fileName is a valid path, else nil
@return an error message if fileName is not a valid path
--]]
function Assets.getRawImage(fileName)
	
	local img = MOAIImage.new()
	-- if the file is "absolute" we need to load the image with absolute 'asDevice' file Name
	if string.starts(fileName,"/") then
		img:load(IO.getAbsolutePath(fileName,true),MOAIImage.PREMULTIPLY_ALPHA)
	else
		img:load(fileName,MOAIImage.PREMULTIPLY_ALPHA)
	end
	local w,h = img:getSize()
	if w == 0 and h == 0 then
		return nil, fileName .. " is not a valid path"
	end	
    return img
end


--[[---
Load a Texture.
@param fileName the name of the texture to load, relative to the working dir or absolute (starting with /)
@param useCache override the default beahviour for caching logic
@return a Texture if fileName is a valid path, else nil
@return an error message if fileName is not a valid path
--]]
function Assets.getTexture(fileName,useCache)
	
	local useCache = (useCache ~= nil) and useCache or Assets.__defaultCacheTexture
	
	local cacheName = IO.getAbsolutePath(fileName)
	
	if __textureCache[cacheName] then
		return __textureCache[cacheName]
	end
	
	local rawImage, err = Assets.getRawImage(fileName)
	if not rawImage then
		return nil, err
	end
	
	local txt = Texture(rawImage)
	if useCache then
		__textureCache[cacheName] = txt
    end
    return txt
end


--[[---
Clear the texture cache.
@param texture can be a Texture or a string (the name of the asset on which the Texture was created).
If no param is provided it clears the whole textureCache
--]]
function Assets.clearTextureCache(texture)
	if texture then
		if type(texture) == 'string' then
			local cacheName = IO.getAbsolutePath(texture)
			if __textureCache[cacheName] then
				__textureCache[cacheName]:dispose()
				__textureCache[cacheName] = nil 
			end
		else
			for k,v in pairs(__textureCache) do
				if v == texture then
					v:dispose()
					__textureCache[k] = nil
					return
				end
			end
		end
	else
		for _,v in pairs(__textureCache) do
			v:dispose()
		end
		table.clear(__textureCache)	
	end
end
