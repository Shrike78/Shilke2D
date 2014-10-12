---Assets namespace provides facilities to load different type of resources.
Assets = {}


--[[---
Load an Xml.
@tparam string fileName the name of the xml to load
@treturn[1] XmlNode
@return[2] nil
@treturn[2] string error message
--]]
function Assets.getXml(fileName)
	return XmlNode.fromFile(fileName)
end


--[[---
Load Json file.
@tparam string fileName the name of the json to load
@treturn[1] table a table rapresenting the json object
@return[2] nil
@treturn[2] string error message
--]]
function Assets.getJson(fileName)
	return Json.fromFile(fileName)
end


--[[---
Load an INI file.
@tparam string fileName the name of the ini to load
@treturn[1] IniParser
@return[2] nil
@treturn[2] string error message
--]]
function Assets.getINI(fileName)
	return IniParser.fromFile(fileName)
end


--[[---
Load a raw image.
@tparam string fileName the name of the raw image to load
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions A ColorTransform value.
@treturn[1] MOAIImage 
@return[2] nil
@treturn[2] string error message
--]]
function Assets.getBitmapData(fileName, transformOptions)
	return BitmapData.fromFile(fileName, transformOptions)
end


--[[---
Load a Texture.
@tparam string fileName the name of the raw data to load
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions A ColorTransform value.
@treturn[1] Texture
@return an error message if fileName is not a valid path
@return[2] nil
@treturn[2] string error message
--]]
function Assets.getTexture(fileName, transformOptions)
    return Texture.fromFile(fileName, transformOptions)
end



--[[---
Load a sound.
@tparam string fileName the name of the sound to load
@treturn[1] Sound
@return[2] nil
@treturn[2] string error message
--]]
function Assets.getSound(fileName)
	local sound = Sound()
	local absFileName = IO.getAbsolutePath(fileName, true)
	sound:load(absFileName)
	--if the file doesn't exist the getLength method returns nil
	if sound:getLength() == nil then
		return nil, fileName .. " is not a valid path"
	end
	return sound
end

