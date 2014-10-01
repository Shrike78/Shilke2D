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
Load a raw image. It's possible to specify a color transformation on load, with PREMULTIPLY_ALPHA as 
default value.
If straight alpha is used configure accordingly the alpha mode of the displayObjects that are going to use
the loaded image.
@param fileName the name of the raw image to load, relative to the working dir or absolute (starting with /)
@param transformOptions[opt] ColorTransform.NONE or a combination of ColorTransform.POW_TWO, 
ColorTransform.QUANTIZE, ColorTransform.TRUECOLOR and ColorTransform.PREMULTIPLY_ALPHA. 
Default value is ColorTransform.PREMULTIPLY_ALPHA.
@return a MOAIImage if fileName is a valid path, else nil
@return an error message if fileName is not a valid path
--]]
function Assets.getRawImage(fileName, transformOptions)
	local transformOptions = transformOptions or ColorTransform.PREMULTIPLY_ALPHA
	local img = MOAIImage.new()
	-- if the file is "absolute" we need to load the image with absolute 'asDevice' file Name
	if string.starts(fileName,"/") then
		img:load(IO.getAbsolutePath(fileName,true),transformOptions)
	else
		img:load(fileName, transformOptions)
	end
	--if premultiply_alpha is used to load, the transparentColor is already forced to 0
	if not BitOp.testflag(transformOptions, ColorTransform.PREMULTIPLY_ALPHA) then
		--If straight alpha is used check if a transparent white or black transformation
		--has been required
		if BitOp.testflag(transformOptions, ColorTransform.TRANSPARENT_BLACK) then
			BitmapData.setTransparentColor(img,Color.BLACK)
		elseif BitOp.testflag(transformOptions, ColorTransform.TRANSPARENT_WHITE) then
			BitmapData.setTransparentColor(img,Color.WHITE)
		end
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
