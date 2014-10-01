--[[---
Set of utilities and constants for BitmapDatas (MOAIImages)
--]]

---define the possible color transform used when loading/converting an image
ColorTransform = 
{
	NONE				= 0,
	POW_TWO 			= MOAIImage.POW_TWO, 			
	QUANTIZE 			= MOAIImage.QUANTIZE, 			
	TRUECOLOR 			= MOAIImage.TRUECOLOR, 		
	PREMULTIPLY_ALPHA	= MOAIImage.PREMULTIPLY_ALPHA,
	TRANSPARENT_BLACK	= 16,
	TRANSPARENT_WHITE	= 32
}

--[[---
BitmapData namespace contains a set of functionalities that extend MOAIImage support.
--]]
BitmapData = {}

--[[---
transform the transparent pixels of a MOAIImage forcing the r,g,b components to a given value
@param img the MOAIImage to transform
@param r a [0..255] value or a Color or hex string
@param g a [0..255] or nil
@param b a [0..255] or nil
@return img return the image itself
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
@param img the MOAIImage to transform
@return img return the image itself
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
