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
@tparam[opt=nil] Texture texture it's possible to provide an already created texture to the method,
avoiding the load (or even for using an alternative image)
@return TextureAtlas
@return err nil or error string if loading failed
--]]
function TexturePacker.loadSparrowFormat(xmlFileName,texture)
	local dir = string.getFileDir(xmlFileName)
	local atlasXml, err = XmlNode.fromFile(xmlFileName)
	if not atlasXml then
		return nil, err
	end
	return TexturePacker.parseSparrowFormat(atlasXml,dir,texture)
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

@tparam XmlNode atlasXml the xml with the atlas descriptor in Sparrow/Starling format
@tparam[opt=nil] string dir by default texture resources are loaded from working directory. 
If dir is provided it load the image referred by atlasXml from dir
@tparam[opt=nil] Texture texture it's possible to provide an already created texture to the method,
avoiding the load (or even for using an alternative image)
@treturn TextureAtlas
--]]
function TexturePacker.parseSparrowFormat(atlasXml, dir, texture)
	
	local imgName = atlasXml:getAttribute("imagePath")
	local extension = "." .. string.getFileExtension(imgName)
	local texture = texture	
	local bTextureOwner = false
	
	if not texture then
		local dir = dir or ""
		if dir ~= "" then
			dir = (dir .. "/"):gsub("//","/")
		end
		texture = Texture.fromFile(dir .. imgName)
		bTextureOwner = true
	end

    local atlas = TextureAtlas(texture, bTextureOwner)
               
    for _,subTex in pairs(atlasXml:getChildren("SubTexture")) do
		--add extension to file name (meant to be the same of atlas img file because 
		--it would have no meaning to have different source file format) so to 
		--be aligned to all the other atlas format and moreover to be transparent
		--when loading a texture using TextureManager
        local name = subTex:getAttribute("name") .. extension
	    local rotated = subTex:getAttributeAsBool("rotated") ~= nil
        local trimmed = subTex:getAttribute("frameX") ~= nil
		
        local x = subTex:getAttributeAsNumber("x")
        local y = subTex:getAttributeAsNumber("y")
        local w = subTex:getAttributeAsNumber("width")
        local h = subTex:getAttributeAsNumber("height")
		--Sparrow/Starling work with (0,0) as top left
        local region = Rect(x, y, w, h)
		
		local frame = nil
		if trimmed then
			--sparrow format uses inverse logic for frameX, frameY
			local frameX = -subTex:getAttributeAsNumber("frameX")
			local frameY = -subTex:getAttributeAsNumber("frameY")
			local frameW = subTex:getAttributeAsNumber("frameWidth")
			local frameH = subTex:getAttributeAsNumber("frameHeight")
			frame = Rect(frameX,frameY,frameW,frameH)
        end
		
        atlas:addRegion(name,region,rotated,frame)
    end
	
    return atlas
end

--[[---
Load a lua file and automatically calls parseMoaiFormat and returns a texture atlas
It expects to have the referred image in a relative path to xml file location 
@param luaFileName the path of the MOAI lua descriptor
@tparam[opt=nil] Texture texture it's possible to provide an already created texture to the method,
avoiding the load (or even for using an alternative image)
@return TextureAtlas
@return err nil or error string if loading failed
--]]
function TexturePacker.loadMoaiFormat(luaFileName,texture)
	local dir = string.getFileDir(luaFileName)
	local atlasDescriptor, err = IO.dofile(luaFileName)
	if not atlasDescriptor then
		return nil, err
	end
	return TexturePacker.parseMoaiFormat(atlasDescriptor, dir, texture)
end


--[[---
Parser for the MOAI lua descriptor
The descriptor must be a lua table with MOAI texture packer export info

@param descriptor the lua table with the atlas descriptor in MOAI format
@tparam[opt=nil] string dir by default texture resources are loaded from working directory. 
If dir is provided it load the image referred by descriptor from dir
@tparam[opt=nil] Texture texture it's possible to provide an already created texture to the method,
avoiding the load (or even for using an alternative image)
--]]
function TexturePacker.parseMoaiFormat(descriptor, dir, texture)
    
	local texture = texture
	local bTextureOwner = false
	
	if not texture then
		local dir = dir or ""
		if dir ~= "" then
			dir = (dir .. "/"):gsub("//","/")
		end
		local imgName = descriptor.texture
		texture = Texture.fromFile(dir .. imgName)
		bTextureOwner = true
	end
	
	local atlas = TextureAtlas(texture, bTextureOwner)

	for _,subTex in pairs(descriptor.frames) do
	
		local rotated = subTex.textureRotated
		local trimmed = subTex.spriteTrimmed
		
		local w,h
		if not rotated then
			w = subTex.spriteColorRect.width
			h = subTex.spriteColorRect.height
		else
			h = subTex.spriteColorRect.width
			w = subTex.spriteColorRect.height
		end
		local x = subTex.uvRect.u0 * w / (subTex.uvRect.u1 - subTex.uvRect.u0)
		local y = subTex.uvRect.v0 * h / (subTex.uvRect.v1 - subTex.uvRect.v0)
		
		local region = Rect(x, y, w, h)
		
		local frame = nil
		if trimmed then
			local frameX = subTex.spriteColorRect.x
			local frameY = subTex.spriteColorRect.y
			local frameW = subTex.spriteSourceSize.width
			local frameH = subTex.spriteSourceSize.height
			frame = Rect(frameX,frameY,frameW,frameH)
		end
		atlas:addRegion(subTex.name, region, rotated, frame)
	end
	return atlas
end
