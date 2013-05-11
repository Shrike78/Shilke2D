--[[---
BlendMode provides constant values for visual blend mode effects. 

A blend mode is always defined by two blendFactor values. 
A blend factor represents a particular four-value vector that is multiplied with the source 
or destination color in the blending formula. 

The blending formula is:

result = source * sourceFactor + destination * destinationFactor

In the formula, the source color is the output color of the pixel shader program.
The destination color is the color that currently exists in the color buffer, as set by 
previous clear and draw operations.
--]]

local BlendFactors = 
{
	--blend factors using premultiplied alpha
	none 		= 	{MOAIProp.GL_ONE, 		MOAIProp.GL_ZERO},
	normal 		= 	{MOAIProp.GL_ONE, 		MOAIProp.GL_ONE_MINUS_SRC_ALPHA},
	add 		= 	{MOAIProp.GL_ONE, 		MOAIProp.GL_ONE},
	multiply 	= 	{MOAIProp.GL_DST_COLOR, MOAIProp.GL_ONE_MINUS_SRC_ALPHA},
	screen 		= 	{MOAIProp.GL_ONE, 		MOAIProp.GL_ONE_MINUS_SRC_COLOR},
	erase 		= 	{MOAIProp.GL_ZERO, 		MOAIProp.GL_ONE_MINUS_SRC_ALPHA}
}

BlendMode = {}

---Deactivates blending disabling any transparency.
BlendMode.NONE = "none"

---The display object appears in front of the background.
BlendMode.NORMAL = "normal"

---Adds the values of the colors of the display object to the colors of its background.
BlendMode.ADD = "add"

---Multiplies the values of the display object colors with the the background color.
BlendMode.MULTIPLY = "multiply"

---Multiplies the complement (inverse) of the display object color with the complement of 
-- the background color, resulting in a bleaching effect.
BlendMode.SCREEN = "screen"

---Erases the background when drawn on a RenderTexture.
BlendMode.ERASE = "erase"

---Returns blendfactors given blendmode enum
--@param blendmode the enum blendmode needed.
--@return srcBlendFactor
--@return dstBlendFactor
function getBlendFactors(blendmode)
	local res = BlendFactors[blendmode]
	assert(res, tostring(blendmode) .. " is an invalid blendMode")
	return unpack(res)
end
