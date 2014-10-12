---Set of utilities and constants for BitmapDatas (MOAIImages)

---define the possible color transform used when loading/converting an image
ColorTransform = 
{
	NONE				= 0,							--no transformation
	POW_TWO 			= MOAIImage.POW_TWO, 			--image is forced to be pow two sized 
	QUANTIZE 			= MOAIImage.QUANTIZE, 			--reduce the number of used colors
	TRUECOLOR 			= MOAIImage.TRUECOLOR, 		--convert indexed to truecolor images
	PREMULTIPLY_ALPHA	= MOAIImage.PREMULTIPLY_ALPHA,	--r,g,b values are premultiplied by alpha value
	TRANSPARENT_BLACK	= 16,							--transparent pixels are set to black r,g,b (straight alpha)
	TRANSPARENT_WHITE	= 32							--transparent pixels are set to white r,g,b (straight alpha)
}

--[[---
BitmapData namespace contains a set of functionalities that extend MOAIImage support.
--]]
BitmapData = {}

--[[---
transform the transparent pixels of a MOAIImage forcing the r,g,b components to a given value
@tparam MOAIImage img the img to transform
@param r a [0..255] value or a Color or hex string
@param g a [0..255] or nil
@param b a [0..255] or nil
@treturn MOAIImage a reference to the image itself
--]]
function BitmapData.setTransparentColor(img, r, g, b)
	local r,g,b,a = Color._paramConversion(r,g,b)
	local w,h = img:getSize()
	for x = 1,w,1 do
		for y = 1,h,1 do
			_,_,_,a = img:getRGBA(x,y)
			if a == 0 then
				img:setRGBA(x,y,r,g,b,a)
			end
		end
	end
	return img
end

--[[---
transform the pixels of a MOAIImage premultiplying the alpha value of each pixel for 
rgb components
@tparam MOAIImage img the MOAIImage to transform
@treturn MOAIImage a reference to the image itself
--]]
function BitmapData.premultiplyAlpha(img)
	local w,h = img:getSize()
	for x = 1,w,1 do
		for y = 1,h,1 do
			local r,g,b,a = img:getRGBA(x,y)
			if a ~= 1 then
				img:setRGBA(x,y,r*a,g*a,b*a,a)
			end
		end
	end
	return img
end

--[[---
Load a raw image. It's possible to specify a color transformation on load, with PREMULTIPLY_ALPHA as 
default value.
If straight alpha is used configure accordingly the alpha mode of the displayObjects that are going to use
the loaded image.
@tparam string fileName the name of the raw image to load
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions 
@treturn[1] MOAIImage
@return[2] nil
@treturn[2] string  error message
--]]
function BitmapData.fromFile(fileName, transformOptions)
	local transformOptions = transformOptions or ColorTransform.PREMULTIPLY_ALPHA
	local img = MOAIImage.new()
	-- if the file is "absolute" we need to load the image with absolute 'asDevice' file Name
	local absFileName = IO.getAbsolutePath(fileName, true)
	img:load(absFileName, transformOptions)
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