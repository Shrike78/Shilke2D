-- Assets

--[[
Assets namespace provides facilities to load and cache different 
type of resources.
--]]

Assets = {}

local __imageCache = {}
local __textureCache = {}

Assets.__defaultUseCache = true

function Assets.getSound(fileName)
	local sound = MOAIUntzSound.new ()
	if string.starts(fileName,"/") then
		local absFileName = IO.getAbsolutePath(fileName)
		sound:load(IO.__baseDir .. absFileName)
	else
		sound:load(fileName)
	end
	return sound
end

function Assets.getRawImage(fileName, useCache)
	
	local useCache = (useCache ~= nil) and useCache or Assets.__defaultUseCache
	
	local cacheName = IO.getAbsolutePath(fileName)
	
	if __imageCache[cacheName] then
		return __imageCache[cacheName]
	end
	
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
	
	if useCache then
		__imageCache[cacheName] = img
	end
	
    return img
end


--return a Texture starting from a raw Image, and caches it once 
--created first time
function Assets.getTexture(fileName,useCache)
	
	local useCache = (useCache ~= nil) and useCache or Assets.__defaultUseCache
	
	local cacheName = IO.getAbsolutePath(fileName)
	
	if __textureCache[cacheName] then
		return __textureCache[cacheName]
	end
	
	local rawImage, err = Assets.getRawImage(fileName,useCache)
	if not rawImage then
		return nil, err
	end
	
	local txt = Texture(rawImage)
	if useCache then
		__textureCache[cacheName] = txt
    end
    return txt
end

--No meaning in storing xml files, do it manually if needed
function Assets.getXml(fileName)
	local xmlFile, err = IO.getFile(fileName)
	if not xmlFile then 
		return nil, err
	end
	return XmlNode.fromString(xmlFile)
end


--clear the cache for a specific file or the whole cache if no fileName is provided
function Assets.clearCache(texture)
	if texture then
		if type(texture) == 'string' then
			local cacheName = IO.getAbsolutePath(texture)
			if __imageCache[cacheName] then __imageCache[cacheName] = nil end
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
		table.clear(__imageCache)
		for _,v in pairs(__textureCache) do
			v:dispose()
		end
		table.clear(__textureCache)	
	end
end
