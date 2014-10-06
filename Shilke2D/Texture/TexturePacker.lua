--[[---
There are several ways to create a texture atlas. 

One solution is the commercial software Texture Packer, that can 
export atlas descriptor for different framework.

Texture Packer namespace provides parsing functions for some
of this descriptors.
--]]

TexturePacker = {}

--[[---
Load an xml file and automatically calls parseSparrowFormat and returns a texture atlas.
It expects to have the referred image in a relative path to xml file location 
@param xmlFileName the path of the Sparrow/Starling xml descriptor
@return TextureAtlas
@return err nil or error string if loading failed
--]]
function TexturePacker.loadSparrowFormat(xmlFileName)
	local dir = string.getFileDir(xmlFileName)
	local atlasXml, err = Assets.getXml(xmlFileName)
	if not atlasXml then
		return nil, err
	end
	return TexturePacker.parseSparrowFormat(atlasXml,dir)
end

--[[---
Parser for the Sparrow/Starling xml descriptor
The descriptor must be an XmlNode and the xml should be in the form:

<TextureAtlas imagePath='atlas.png'>
    <SubTexture name='texture_1' x='0'  y='0' width='50' height='50'/>
    <SubTexture name='texture_2' x='50' y='0' width='20' height='30'/>
</TextureAtlas>

It doesn't support trimming

NB: in Starling format subtexture's names are without original image extension.
By design choice, the name of each subtexture once loaded append as extension the 
extension of the atlas resource.

@param atlasXml the xml with the atlas descriptor in Sparrow/Starling format
@param dir by default texture resources are loaded from working directory. 
If dir is provided it load the image referred by atlasXml from dir
@param texture it's possible to provide an already created texture to the method,
avoiding the load (or even for using an alternative image)
--]]
function TexturePacker.parseSparrowFormat(atlasXml, dir, texture)
	
	local imgName = atlasXml:getAttribute("imagePath")
	local extension = "." .. string.getFileExtension(imgName)
	local texture = texture	
	
	if not texture then
		local dir = dir or ""
		if dir ~= "" then
			dir = (dir .. "/"):gsub("//","/")
		end
		texture = Assets.getTexture(dir .. imgName)
	end

    local atlas = TextureAtlas(texture)
               
    for _,subTex in pairs(atlasXml:getChildren("SubTexture")) do
		--add extension to file name (meant to be the same of atlas img file because 
		--it would have no meaning to have different source file format) so to 
		--be aligned to all the other atlas format and moreover to be transparent
		--when loading a texture using TextureManager
        local name = subTex:getAttribute("name") .. extension
        --divide for width/height to have a [0..1] range
        local x = subTex:getAttributeAsNumber("x") / texture.width
        local y = subTex:getAttributeAsNumber("y") / texture.height
        local w = subTex:getAttributeAsNumber("width") / texture.width
        local h = subTex:getAttributeAsNumber("height") / texture.height
        local rotated = subTex:getAttributeAsBool("rotated", false)
        --Sparrow/Starling work with (0,0) as top left
        local region = Rect(x, y, w, h)
        atlas:addRegion(name,region, rotated)
    end
	
    return atlas
end


--[[---
Load a lua file and automatically calls parseMoaiFormat and returns a texture atlas
It expects to have the referred image in a relative path to xml file location 
@param luaFileName the path of the MOAI lua descriptor
@return TextureAtlas
@return err nil or error string if loading failed
--]]
function TexturePacker.loadMoaiFormat(luaFileName)
	local dir = string.getFileDir(luaFileName)
	local atlasDescriptor, err = IO.dofile(luaFileName)
	if not atlasDescriptor then
		return nil, err
	end
	return TexturePacker.parseMoaiFormat(atlasDescriptor, dir)
end


--[[---
Parser for the MOAI lua descriptor
The descriptor must be a lua table with MOAI texture packer export info

@param descriptor the lua table with the atlas descriptor in MOAI format
@param dir by default texture resources are loaded from working directory. 
If dir is provided it load the image referred by atlasXml from dir
@param texture it's possible to provide an already created texture to the method,
avoiding the load (or even for using an alternative image)
--]]
function TexturePacker.parseMoaiFormat(descriptor, dir, texture)
    
	local texture = texture
	if not texture then
		local dir = dir or ""
		if dir ~= "" then
			dir = (dir .. "/"):gsub("//","/")
		end
		local imgName = descriptor.texture
		texture = Assets.getTexture(dir .. imgName)
	end
	
	local atlas = TextureAtlas(texture)

	for _,subTex in pairs(descriptor.frames) do
		local x = subTex.uvRect.u0
		local y = subTex.uvRect.v0
		local w = subTex.uvRect.u1 - x
		local h = subTex.uvRect.v1 - y
		local rotated = subTex.textureRotated
		local region = Rect(x, y, w, h)
		atlas:addRegion(subTex.name, region, rotated)
	end
	return atlas
end

--[[---
Load a lua file and automatically calls parseCoronaFormat and returns a texture atlas
It expects to have the referred image in a relative path to xml file location 
@param luaFileName the path of the Corona lua descriptor
@return TextureAtlas
@return err nil or error string if loading failed
--]]
function TexturePacker.loadCoronaFormat(luaFileName)
	local dir = string.getFileDir(luaFileName)
	local atlasDescriptor, err = IO.dofile(luaFileName)
	if not atlasDescriptor then
		return nil, err
	end
	return TexturePacker.parseCoronaFormat(atlasDescriptor, dir)
end

--[[---
Parser for the Corona lua descriptor
The descriptor must be a lua table with Corona texture packer export info

@param descriptor the lua table with the atlas descriptor in Corona format
@param texture it's necessary to provide an already created texture to the method
--]]
function TexturePacker.parseCoronaFormat(descriptor,texture)
	local atlas = TextureAtlas(texture)
    for _,subTex in pairs(descriptor.frames) do
        local x = subTex.textureRect.x / texture.width
        local y = subTex.textureRect.y / texture.height
        local w = subTex.textureRect.width / texture.width
        local h = subTex.textureRect.height / texture.height
        
        --Sparrow/Starling work with (0,0) as top left
        local region = Rect(x, y, w, h)
        atlas:addRegion(subTex.name,region)
    end
    return atlas
end
