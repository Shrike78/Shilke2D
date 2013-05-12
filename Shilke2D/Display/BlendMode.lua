--[[---
BlendMode provides constant values for visual blend mode effects. 

A blend mode is always defined by two blendFactor values. 
A blend factor represents a particular four-value vector that is multiplied with the source 
or destination color in the blending formula. 

The default GL_FUNC_ADD blending equation formula is:

result = source * sourceFactor + destination * destinationFactor

In the formula, the source color is the output color of the pixel shader program.
The destination color is the color that currently exists in the color buffer, as set by 
previous clear and draw operations.
--]]

---BlendMode namespace contains enums for OpenGL blend factors and blend equations and
--also specific Shilke2D enums for typical blend modes
BlendMode = 
{
	GL_FUNC_ADD 				= MOAIProp.GL_FUNC_ADD,
	GL_FUNC_SUBTRACT 			= MOAIProp.GL_FUNC_SUBTRACT,
	GL_FUNC_REVERSE_SUBTRACT 	= MOAIProp.GL_FUNC_REVERSE_SUBTRACT,

	GL_ONE 						= MOAIProp.GL_ONE,
	GL_ZERO 					= MOAIProp.GL_ZERO,
	GL_DST_ALPHA 				= MOAIProp.GL_DST_ALPHA,
	GL_DST_COLOR 				= MOAIProp.GL_DST_COLOR,
	GL_SRC_COLOR 				= MOAIProp.GL_SRC_COLOR,
	GL_ONE_MINUS_DST_ALPHA		= MOAIProp.GL_ONE_MINUS_DST_ALPHA,
	GL_ONE_MINUS_DST_COLOR		= MOAIProp.GL_ONE_MINUS_DST_COLOR,
	GL_ONE_MINUS_SRC_ALPHA 		= MOAIProp.GL_ONE_MINUS_SRC_ALPHA,
	GL_ONE_MINUS_SRC_COLOR 		= MOAIProp.GL_ONE_MINUS_SRC_COLOR,
	GL_SRC_ALPHA 				= MOAIProp.GL_SRC_ALPHA,
	GL_SRC_ALPHA_SATURATE 		= MOAIProp.GL_SRC_ALPHA_SATURATE,	
}	

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

---Erases the background when drawn.
BlendMode.ERASE = "erase"

local BlendFactors = 
{
	--no premultiplied alpha
	[0] = 
	{
		none 		= 	{BlendMode.GL_ONE, 			BlendMode.GL_ZERO},
		normal 		= 	{BlendMode.GL_SRC_ALPHA, 	BlendMode.GL_ONE_MINUS_SRC_ALPHA},
		add 		= 	{BlendMode.GL_SRC_ALPHA, 	BlendMode.GL_DST_ALPHA},
		multiply 	= 	{BlendMode.GL_DST_COLOR, 	BlendMode.GL_ONE_MINUS_SRC_ALPHA},
		screen 		= 	{BlendMode.GL_SRC_APHA,		BlendMode.GL_ONE},
		erase 		= 	{BlendMode.GL_ZERO, 		BlendMode.GL_ONE_MINUS_SRC_ALPHA}
	},
	--premultiplied alpha
	[1] = 
	{
		none 		= 	{BlendMode.GL_ONE, 			BlendMode.GL_ZERO},
		normal 		= 	{BlendMode.GL_ONE, 			BlendMode.GL_ONE_MINUS_SRC_ALPHA},
		add 		= 	{BlendMode.GL_ONE, 			BlendMode.GL_ONE},
		multiply 	= 	{BlendMode.GL_DST_COLOR, 	BlendMode.GL_ONE_MINUS_SRC_ALPHA},
		screen 		= 	{BlendMode.GL_ONE, 			BlendMode.GL_ONE_MINUS_SRC_COLOR},
		erase 		= 	{BlendMode.GL_ZERO, 		BlendMode.GL_ONE_MINUS_SRC_ALPHA}
	}
}


--[[---
Returns blendfactors given blendmode enum
@param blendmode the enum blendmode needed.
@param pma [optional] Used to select if with premultipied alpha or not. Default is true.
@return srcBlendFactor
@return dstBlendFactor
--]]
function getBlendFactors(blendmode,pma)
	local pma = (pma == false) and 0 or 1
	local res = BlendFactors[pma][blendmode]
	assert(res, tostring(blendmode) .. " is an invalid blendMode")
	return unpack(res)
end
