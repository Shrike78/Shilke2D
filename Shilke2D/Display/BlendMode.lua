--[[---
Constant values for visual blend mode effects. 
 
Blend Modes changes how display objects are rendered.

The blend equation is:

result = BlendEquation(source * sourceBlendFactor, dest * destBlendFactor)

In the formula, the source color is the output color of the pixel shader program. 
The destination color is the color that currently exists in the color buffer, as 
set by previous clear and draw operations.

There're three possible blend equation and the default (and mainly used) is 
GL_FUNC_ADD:

result = source * sourceBlendFactor + dest * destBlendFactor

Beware that blending factors produce different output depending on the displayObject and the
alpha logic used: objects may have 'premultiplied alpha' (pma), which means that their RGB values are 
multiplied with their alpha value, or straight alpha (where rgb value are kept untouched).

Premultiplied alpha is the default because it save processing time. 
For example, blendmode normal is:

Straight alpha: 		GL_FUNC_ADD(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) 
						(source * src_alpha + dest * (1-dst_alpha)

Premultiplied alpha: 	GL_FUNC_ADD(GL_SRC_ONE, GL_ONE_MINUS_SRC_ALPHA)
						(source + dest * (1-dst_alpha)

that save a multiplication for each pixel at rendering time, because the multiplication has been done 
at setup time once.
--]]


--[[---
The different blend equation that can be used to define a blend mode
--]]
BlendEquation = 
{
	GL_FUNC_ADD 				= MOAIProp.GL_FUNC_ADD,
	GL_FUNC_SUBTRACT 			= MOAIProp.GL_FUNC_SUBTRACT,
	GL_FUNC_REVERSE_SUBTRACT 	= MOAIProp.GL_FUNC_REVERSE_SUBTRACT,
}

--[[---
return the name of a given blend equation
@param equation a BlendEquation enum
@return string blend equation name
--]]
function BlendEquation.toString(equation)
	local _names = {}
	_names[MOAIProp.GL_FUNC_ADD] 					= "GL_FUNC_ADD"
	_names[MOAIProp.GL_FUNC_SUBTRACT] 				= "GL_FUNC_SUBTRACT"
	_names[MOAIProp.GL_FUNC_REVERSE_SUBTRACT] 	= "GL_FUNC_REVERSE_SUBTRACT"
	return _names[equation]
end



--[[---
The different blend factor that can be used as source and destination factors 
to define a blend mode
--]]
BlendFactor = 
{
	GL_ONE 						= MOAIProp.GL_ONE,
	GL_ZERO 					= MOAIProp.GL_ZERO,
	GL_DST_ALPHA 				= MOAIProp.GL_DST_ALPHA,
	GL_DST_COLOR 				= MOAIProp.GL_DST_COLOR,
	GL_SRC_COLOR 				= MOAIProp.GL_SRC_COLOR,
	GL_ONE_MINUS_DST_ALPHA		= MOAIProp.GL_ONE_MINUS_DST_ALPHA,
	GL_ONE_MINUS_DST_COLOR		= MOAIProp.GL_ONE_MINUS_DST_COLOR,
	GL_ONE_MINUS_SRC_ALPHA 	= MOAIProp.GL_ONE_MINUS_SRC_ALPHA,
	GL_ONE_MINUS_SRC_COLOR 	= MOAIProp.GL_ONE_MINUS_SRC_COLOR,
	GL_SRC_ALPHA 				= MOAIProp.GL_SRC_ALPHA,
	GL_SRC_ALPHA_SATURATE 		= MOAIProp.GL_SRC_ALPHA_SATURATE,	
}

--[[---
return the name of a given blend factor
@param factor a BlendFactor enum
@return string blend factor name
--]]
function BlendFactor.toString(factor)
	local _names = {}
	_names[MOAIProp.GL_ONE] 					= "GL_ONE"
	_names[MOAIProp.GL_ZERO] 					= "GL_ZERO"
	_names[MOAIProp.GL_DST_ALPHA]				= "GL_DST_ALPHA"
	_names[MOAIProp.GL_DST_COLOR]				= "GL_DST_COLOR"
	_names[MOAIProp.GL_SRC_COLOR]				= "GL_SRC_COLOR"
	_names[MOAIProp.GL_ONE_MINUS_DST_ALPHA]	= "GL_ONE_MINUS_DST_ALPHA"
	_names[MOAIProp.GL_ONE_MINUS_DST_COLOR]	= "GL_ONE_MINUS_DST_COLOR"
	_names[MOAIProp.GL_ONE_MINUS_SRC_ALPHA] 	= "GL_ONE_MINUS_SRC_ALPHA"
	_names[MOAIProp.GL_ONE_MINUS_SRC_COLOR] 	= "GL_ONE_MINUS_SRC_COLOR"
	_names[MOAIProp.GL_SRC_ALPHA] 				= "GL_SRC_ALPHA"
	_names[MOAIProp.GL_SRC_ALPHA_SATURATE] 	= "GL_SRC_ALPHA_SATURATE"
	return _names[factor]
end



--[[---
BlendMode namespace contains a list of blend mode presets and functionalities to register / retrieve
blend modes
--]]
BlendMode = {
	NONE 		= "none",		---Deactivates blending disabling any transparency.
	NORMAL 		= "normal",		---The display object appears in front of the background.
	ADD 		= "add", 		---Adds the values of the colors of the display object to the colors of its background.
	MULTIPLY 	= "multiply", 	---Multiplies the values of the display object colors with the the background color.
	SCREEN 		= "screen",		---Multiplies the complement of the display object color with the complement of the background color, resulting in a bleaching effect.
	ERASE 		= "erase",		---Erases the background when drawn.
	BELOW 		= "below"		---Draws under/below existing objects.
}

local _blendModes = 
{
	--no premultiplied alpha
	[0] = 
	{
		none		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_SRC_ALPHA, 	BlendFactor.GL_ZERO},
		normal 	 	= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_SRC_ALPHA, 	BlendFactor.GL_ONE_MINUS_SRC_ALPHA},
		add			= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_SRC_ALPHA, 	BlendFactor.GL_DST_ALPHA},
		multiply	= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_DST_COLOR, 	BlendFactor.GL_ONE_MINUS_SRC_ALPHA},
		screen 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_SRC_ALPHA,	BlendFactor.GL_ONE},
		erase 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ZERO, 		BlendFactor.GL_ONE_MINUS_SRC_ALPHA},
		below 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ONE_MINUS_DST_ALPHA, BlendFactor.GL_DST_ALPHA}
	},
	--premultiplied alpha
	[1] = 
	{
		none 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ONE, 		BlendFactor.GL_ZERO},
		normal 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ONE, 		BlendFactor.GL_ONE_MINUS_SRC_ALPHA},
		add 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ONE, 		BlendFactor.GL_ONE},
		multiply 	= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_DST_COLOR, 	BlendFactor.GL_ONE_MINUS_SRC_ALPHA},
		screen 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ONE, 		BlendFactor.GL_ONE_MINUS_SRC_COLOR},
		erase 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ZERO, 		BlendFactor.GL_ONE_MINUS_SRC_ALPHA},
		below 		= 	{BlendEquation.GL_FUNC_ADD,	BlendFactor.GL_ONE_MINUS_DST_ALPHA, BlendFactor.GL_DST_ALPHA}

	}
}

--[[---
allow to register a named blend mode. A named blend mode is registered only for a specific
alpha mode (premultiplied or straight)
@param blendmode the name to register with the new blend mode
@param pma bool if the blendmode is registered for premultiplied or straight alpha
@param blendEquation the blend equation
@param srcFactor the the src blend factor
@param dstFactor the the dst blend factor
@return bool true if the new mode is registered, false if a blend mode with the provided name already 
exist for choosen alpha mode
--]]
function  BlendMode.register(blendmode, pma, blendEquation, srcFactor, dstFactor)
	local pma = (pma == false) and 0 or 1
	local res = _blendModes[pma][blendmode]
	if res then
		return false
	end
	_blendModes[pma][blendmode] = {blendEquation, srcFactor, dstFactor}
	return true
end

--[[---
Enumerate all the available registered blend modes for choosen alpha mode
@param pma boolean value, if for premultiplied or straight alpha mode
@return table a list of all the available blendmode names
--]]
function BlendMode.getRegisteredModes(pma)
	local pma = (pma == false) and 0 or 1
	local modes = {}
	for k,v in pairs(_blendModes[pma]) do
		modes[#modes+1] = k
	end
	return modes
end

--[[---
Returns blend equation and blend factors of a registered (or preset) blendmode
@param blendmode the enum blendmode needed.
@param pma [optional] Used to select if with premultipied alpha or not. Default is true.
@return blendEquation
@return srcBlendFactor
@return dstBlendFactor
--]]
function BlendMode.getParams(blendmode, pma)
	local pma = (pma == false) and 0 or 1
	local res = _blendModes[pma][blendmode]
	if not res then
		error(tostring(blendmode) .. " is an invalid blendMode")
		return nil, nil, nil
	end
	return unpack(res)
end


