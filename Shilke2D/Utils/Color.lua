--[[---
Color class.

Shilke2D uses colors in a (0,255) space, while MOAI in a (0,1). It's assumed everywhere that a 
color is in a Shilke2D (0,255) space, so the unpack_normalized is used whenever a color must be provided
to MOAI interface. The call returns each color component divided by 255

There is no real assumption about the values of rgba components, they can be 
also negative. Algebrical operators between colors are defined and can produced meaningless colors, 
with component values outside the (0,255) range. Algebrical operator are meant to support color animations 
by tweening and should never be used explicitely.

A set of predefined named colors is also provided. All the color are fully opaque(alpha is 255).
The color definition is taken from:

<a href="http://www.w3.org/TR/SVG/types.html#ColorKeywords">http://www.w3.org/TR/SVG/types.html#ColorKeywords</a>

--]]
Color = class()


--[[
todo: 
-rgb2hsv
-hsl2rgb
-rgb2hsl
-function to add / subtract / multiply / divide ecc. colors with rgb components, saturation ecc. 
differs from algebrical operations
--]]


local floor = math.floor
local clamp = math.clamp
local INV_255 = 1/255
local INV_256 = 1/256

---Constructor.
--@tparam[opt=255] int r
--@tparam[opt=255] int g
--@tparam[opt=255] int b
--@tparam[opt=255] int a
function Color:init(r,g,b,a)
	self.r = r or 255
	self.g = g or 255
	self.b = b or 255
	self.a = a or 255
end

---Returns the 4 components
--@tparam[opt=false] bool clamp if true return values are clamped in (0,255).
--@treturn number r (0,255)
--@treturn number g (0,255)
--@treturn number b (0,255)
--@treturn number a (0,255)
function Color:unpack(clamp)
	local r,g,b,a = self.r, self.g, self.b, self.a
	if clamp then
		r,g,b,a = clamp(r,0,255), clamp(g,0,255), clamp(b,0,255), clamp(a,0,255)
	end
	return r,g,b,a
end
	
---Returns the 4 components normalized
--@tparam[opt=false] bool clamp if true return values are clamped in (0,1)
--@treturn number r (0,1)
--@treturn number g (0,1)
--@treturn number b (0,1)
--@treturn number a (0,1)
function Color:unpack_normalized(clamp)
	local r,g,b,a = self:unpack(clamp)
	r,g,b,a = r * INV_255, g * INV_255, b * INV_255, a * INV_255
	return r,g,b,a
end

---Force the components values to be clamped between (0,255). 
--They could be out of range after algebrical operations
function Color:clamp()
	self.r = clamp(self.r,0,255)
	self.g = clamp(self.g,0,255)
	self.b = clamp(self.b,0,255) 
	self.a = clamp(self.a,0,255)
end

--[[---
sum r,g,b,a channels of two colors
@treturn Color c1+c2
--]]
function Color.__add(c1,c2)
	return Color(
			c1.r + c2.r,
			c1.g + c2.g,
			c1.b + c2.b,
			c1.a + c2.a
		)
end

--[[---
subtract r,g,b,a channels of two colors
@treturn Color c1+c2
--]]
function Color.__sub(c1,c2)
	return Color(
			c1.r - c2.r,
			c1.g - c2.g,
			c1.b - c2.b,
			c1.a - c2.a
		)
end

--[[---
multiply r,g,b,a channels of a color by a number
__mul accept number multiplier either as left or right operator
@treturn Color c1 * m
--]]
function Color.__mul(c1,c2)
	if type(c1) == "number" then
		return Color(
			c1 * c2.r, 
			c1 * c2.g,
			c1 * c2.b,
			c1 * c2.a
		)
	elseif type(c2) == "number" then
		return Color(
			c2 * c1.r,
			c2 * c1.g,
			c2 * c1.b,
			c2 * c1.a
		)
	else
		error("invalid operation on color")
	end
end

---divide r,g,b,a components of a color by a number
--@treturn Color c/d
function Color.__div(c,d)
	return Color(
		c.r/d, 
		c.g/d,
		c.b/d,
		c.a/d
	)
end

---the == operation
function Color.__eq(c1,c2)
	return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b and c1.a == c2.a
end

---print color components value
function Color:__tostring()
	return "("..self.r..","..self.g..","..self.b..","..self.a..")"
end

---blend 2 colors
--@tparam Color c1 
--@tparam Color c2
--@tparam number w blend factor (0,1)
--@treturn Color c1*a + c2*(1-a)
function Color.blend(c1, c2, w)
	return Color(	
					c1.r * w + c2.r * (1-w),
					c1.g * w + c2.g * (1-w),
					c1.b * w + c2.b * (1-w),
					c1.a * w + c2.a * (1-w)
				)
end

--[[---
color space conversion
@tparam number h (0,1)
@tparam number s (0,1)
@tparam number v (0,1)
@treturn int r (0,255)
@treturn int g (0,255)
@treturn int b (0,255)
--]]
function Color.hsv2rgb(h, s, v)

    -- h, s, v is allowed having values between [0 ... 1].

    h = 6 * h
    local i = floor(h - 0.000001)
    local f = h - i
    local m = v*(1-s)
    local n = v*(1-s*f)
    local k = v*(1-s*(1-f))
    local r,g,b
    
    if i<=0 then
        r = v; g = k; b = m
    elseif i==1 then
        r = n; g = v; b = m
    elseif i==2 then
        r = m; g = v; b = k
    elseif i==3 then
        r = m; g = n; b = v
    elseif i==4 then
        r = k; g = m; b = v
    elseif i==5 then
        r = v; g = m; b = n
    end
    return floor(r*255), floor(g*255), floor(b*255)
end

---Pack an r,g,b,a set of values to a single int value
--@tparam int r (0,255)
--@tparam int g (0,255)
--@tparam int b (0,255)
--@tparam int a (0,255)
--@treturn int
function Color.rgba2int(r,g,b,a)
	local r = floor(r)
	local g = floor(g)
	local b = floor(b)
	local a = floor(a)
	return ((a * 256 + r) * 256 + g) * 256 + b
end

---Unpack an int value to a set of r,g,b,a values
--@tparam int c value to be unpack
--@treturn int r (0,255)
--@treturn int g (0,255)
--@treturn int b (0,255)
--@treturn int a (0,255)
function Color.int2rgba(c)
	local b = c % 256
	c = c * INV_256
	local g = c % 256
	c = c * INV_256
	local r = c % 256
	c = c * INV_256
	local a = c % 256
	return floor(r), floor(g), floor(b), floor(a)
end

---Create a color starting from an int value, using int2rgba conversion
--@tparam int c
--@treturn Color
function Color.fromInt(c)
	return Color(Color.int2rgba(c))
end

--[[---
convert an hex color string (that can start or not with #) to r,g,b,a (0,255) values 
@tparam string hex string defining color
@treturn int r (0,255)
@treturn int g (0,255)
@treturn int b (0,255)
@treturn int a v if the hex string doesn't contains alpha info it returns 255
--]]
function Color.hex2rgba(hex)
    hex = hex:gsub("#","")
	local l = hex:len()
	if l == 6 then
		return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), 
			tonumber("0x"..hex:sub(5,6)), 255
	elseif l == 8 then
		return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), 
			tonumber("0x"..hex:sub(5,6)), tonumber("0x"..hex:sub(7,8))
	else
		error("wrong parameter")
	end
end


--[[---
Create a Color starting from an hex string using hex2rgba conversion
@tparam string hex string defining color
@treturn Color
--]]
function Color.fromHex(hex)
	return Color(Color.hex2rgba(hex))
end

--[[---
create a Color given r,g,b,a as float (0,1) values
@tparam number r (0,1)
@tparam number g (0,1)
@tparam number b (0,1)
@tparam number a (0,1)
@treturn Color 
--]]
function Color.fromNormalizedValues(r,g,b,a)
	return Color(
		math.round(r*255), 
		math.round(g*255), 
		math.round(b*255), 
		math.round(a*255)
	)
end


--[[---
Utility function used by functions that want to accept color expressed either as
Color object or as (0,255) rgb or rgba values or as hex string. 

It' possible to provide also a "default alpha value" to be used as return value with 
the r,g,b (0,255) configuration in case of nil alpha. 

@param r (0,255) value or Color object or hex string
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt] (0,255) value or nil
@param da[opt] (0,255) default alpha value.
@return _r (0,1)
@return _g (0,1)
@return _b (0,1)
@return _a (0,1) (or provided default alpha value)
--]]
function Color._paramConversion(r,g,b,a,da)
	local _r,_g,_b,_a
	local t = class_type(r)
	if t == Color then
		_r,_g,_b,_a = r:unpack_normalized()
	elseif t == 'number' then
		_r = r * INV_255
		_g = g * INV_255
		_b = b * INV_255
		_a = a and (a * INV_255) or da
	elseif t == 'string' then
		_r, _g, _b, _a = Color.hex2rgba(r)
		_r = _r * INV_255
		_g = _g * INV_255
		_b = _b * INV_255
		_a = _a * INV_255
	else
		error("no suitable conversion of this parameters")
	end
	return _r,_g,_b,_a
end

--list of predefined named colors
Color.ALICEBLUE			= Color(240,248,255)	--- (240,248,255)
Color.ANTIQUEWHITE			= Color(250,235,215)	--- (250,235,215)
Color.AQUA					= Color(0,255,255)		--- (0,255,255)
Color.AQUAMARINE			= Color(127,255,212)	--- (127,255,212)
Color.AZURE					= Color(240,255,255)	--- (240,255,255)
Color.BEIGE					= Color(245,245,220)	--- (245,245,220)
Color.BISQUE				= Color(255,228,196)	--- (255,228,196)
Color.BLACK					= Color(0,0,0)			--- (0,0,0)
Color.BLANCHEDALMOND		= Color(255,235,205)	--- (255,235,205)
Color.BLUE					= Color(0,0,255)		--- (0,0,255)
Color.BLUEVIOLET			= Color(138,43,226)		--- (138,43,226)
Color.BROWN					= Color(165,42,42)		--- (165,42,42)
Color.BURLYWOOD			= Color(222,184,135)	--- (222,184,135)
Color.CADETBLUE			= Color(95,158,160)		--- (95,158,160)
Color.CHARTREUSE			= Color(127,255,0)		--- (127,255,0)
Color.CHOCOLATE			= Color(210,105,30)		--- (210,105,30)
Color.CORAL					= Color(255,127,80)		--- (255,127,80)
Color.CORNFLOWERBLUE		= Color(100,149,237)	--- (100,149,237)
Color.CORNSILK				= Color(255,248,220)	--- (255,248,220)
Color.CRIMSON				= Color(220,20,60)		--- (220,20,60)
Color.CYAN					= Color(0,255,255)		--- (0,255,255)
Color.DARKBLUE				= Color(0,0,139)		--- (0,0,139)
Color.DARKCYAN				= Color(0,139,139)		--- (0,139,139)
Color.DARKGOLDENROD		= Color(184,134,11)		--- (184,134,11)
Color.DARKGRAY				= Color(169,169,169)	--- (169,169,169)
Color.DARKGREY				= Color(169,169,169)	--- (169,169,169)
Color.DARKGREEN			= Color(0,100,0)		--- (0,100,0)
Color.DARKKHAKI			= Color(189,183,107)	--- (189,183,107)
Color.DARKMAGENTA			= Color(139,0,139)		--- (139,0,139)
Color.DARKOLIVEGREEN		= Color(85,107,47)		--- (85,107,47)
Color.DARKORANGE			= Color(255,140,0)		--- (255,140,0)
Color.DARKORCHID			= Color(153,50,204)		--- (153,50,204)
Color.DARKRED				= Color(139,0,0)		--- (139,0,0)
Color.DARKSALMON			= Color(233,150,122)	--- (233,150,122)
Color.DARKSEAGREEN			= Color(143,188,143)	--- (143,188,143)
Color.DARKSLATEBLUE		= Color(72,61,139)		--- (72,61,139)
Color.DARKSLATEGRAY		= Color(47,79,79)		--- (47,79,79)
Color.DARKSLATEGREY		= Color(47,79,79)		--- (47,79,79)
Color.DARKTURQUOISE		= Color(0,206,209)		--- (0,206,209)
Color.DARKVIOLET			= Color(148,0,211)		--- (148,0,211)
Color.DEEPPINK				= Color(255,20,147)		--- (255,20,147)
Color.DEEPSKYBLUE			= Color(0,191,255)		--- (0,191,255)
Color.DIMGRAY				= Color(105,105,105)	--- (105,105,105)
Color.DIMGREY				= Color(105,105,105)	--- (105,105,105)
Color.DODGERBLUE			= Color(30,144,255)		--- (30,144,255)
Color.FIREBRICK			= Color(178,34,34)		--- (178,34,34)
Color.FLORALWHITE			= Color(255,250,240)	--- (255,250,240)
Color.FORESTGREEN			= Color(34,139,34)		--- (34,139,34)
Color.FUCHSIA				= Color(255,0,255)		--- (255,0,255)
Color.GAINSBORO			= Color(220,220,220)	--- (220,220,220)
Color.GHOSTWHITE			= Color(248,248,255)	--- (248,248,255)
Color.GOLD					= Color(255,215,0)		--- (255,215,0)
Color.GOLDENROD			= Color(218,165,32) 	--- (218,165,32)
Color.GRAY					= Color(128,128,128)	--- (128,128,128)
Color.GREY					= Color(128,128,128)	--- (128,128,128)
Color.GREEN					= Color(0,128,0)		--- (0,128,0)
Color.GREENYELLOW			= Color(173,255,47)		--- (173,255,47)
Color.HONEYDEW				= Color(240,255,240)	--- (240,255,240)
Color.HOTPINK				= Color(255,105,180)	--- (255,105,180)
Color.INDIANRED			= Color(205,92,92)		--- (205,92,92)
Color.INDIGO				= Color(75,0,130)		--- (75,0,130)
Color.IVORY					= Color(255,255,240)	--- (255,255,240)
Color.KHAKI					= Color(240,230,140)	--- (240,230,140)
Color.LAVENDER				= Color(230,230,250)	--- (230,230,250)
Color.LAVENDERBLUSH		= Color(255,240,245)	--- (255,240,245)
Color.LAWNGREEN			= Color(124,252,0)		--- (124,252,0)
Color.LEMONCHIFFON			= Color(255,250,205)	--- (255,250,205)
Color.LIGHTBLUE			= Color(173,216,230)	--- (173,216,230)
Color.LIGHTCORAL			= Color(240,128,128)	--- (240,128,128)
Color.LIGHTCYAN			= Color(224,255,255)	--- (224,255,255)
Color.LIGHTGOLDENRODYELLOW	= Color(250,250,210)	--- (250,250,210)
Color.LIGHTGRAY			= Color(211,211,211)	--- (211,211,211)
Color.LIGHTGREY			= Color(211,211,211)	--- (211,211,211)
Color.LIGHTGREEN			= Color(144,238,144)	--- (144,238,144)
Color.LIGHTPINK			= Color(255,182,193)	--- (255,182,193)
Color.LIGHTSALMON			= Color(255,160,122)	--- (255,160,122)
Color.LIGHTSEAGREEN		= Color(32,178,170) 	--- (32,178,170)
Color.LIGHTSKYBLUE			= Color(135,206,250)	--- (135,206,250)
Color.LIGHTSLATEGRAY		= Color(119,136,153)	--- (119,136,153)
Color.LIGHTSLATEGREY		= Color(119,136,153)	--- (119,136,153)
Color.LIGHTSTEELBLUE		= Color(176,196,222)	--- (176,196,222)
Color.LIGHTYELLOW			= Color(255,255,224)	--- (255,255,224)
Color.LIME					= Color(0,255,0)		--- (0,255,0)
Color.LIMEGREEN			= Color(50,205,50)		--- (50,205,50)
Color.LINEN					= Color(250,240,230)	--- (250,240,230)
Color.MAGENTA				= Color(255,0,255)		--- (255,0,255)
Color.MAROON				= Color(128,0,0)		--- (128,0,0)
Color.MEDIUMAQUAMARINE		= Color(102,205,170)	--- (102,205,170)
Color.MEDIUMBLUE			= Color(0,0,205)		--- (0,0,205)
Color.MEDIUMORCHID			= Color(186,85,211)		--- (186,85,211)
Color.MEDIUMPURPLE			= Color(147,112,219)	--- (147,112,219)
Color.MEDIUMSEAGREEN		= Color(60,179,113)		--- (60,179,113)
Color.MEDIUMSLATEBLUE		= Color(123,104,238) 	--- (123,104,238)
Color.MEDIUMSPRINGGREEN	= Color(0,250,154) 		--- (0,250,154)
Color.MEDIUMTURQUOISE		= Color(72,209,204)		--- (72,209,204)
Color.MEDIUMVIOLETRED		= Color(199,21,133)		--- (199,21,133)
Color.MIDNIGHTBLUE			= Color(25,25,112)		--- (25,25,112)
Color.MINTCREAM			= Color(245,255,250)	--- (245,255,250)
Color.MISTYROSE			= Color(255,228,225)	--- (255,228,225)
Color.MOCCASIN				= Color(255,228,181)	--- (255,228,181)
Color.NAVAJOWHITE			= Color(255,222,173)	--- (255,222,173)
Color.NAVY					= Color(0,0,128)		--- (0,0,128)
Color.OLDLACE				= Color(253,245,230)	--- (253,245,230)
Color.OLIVE					= Color(128,128,0)		--- (128,128,0)
Color.OLIVEDRAB			= Color(107,142,35)		--- (107,142,35)
Color.ORANGE				= Color(255,165,0)		--- (255,165,0)
Color.ORANGERED			= Color(255,69,0)		--- (255,69,0)
Color.ORCHID				= Color(218,112,214)	--- (218,112,214)
Color.PALEGOLDENROD		= Color(238,232,170)	--- (238,232,170)
Color.PALEGREEN			= Color(152,251,152)	--- (152,251,152)
Color.PALETURQUOISE		= Color(175,238,238)	--- (175,238,238)
Color.PALEVIOLETRED		= Color(219,112,147)	--- (219,112,147)
Color.PAPAYAWHIP			= Color(255,239,213)	--- (255,239,213)
Color.PEACHPUFF			= Color(255,218,185)	--- (255,218,185)
Color.PERU					= Color(205,133,63)		--- (205,133,63)
Color.PINK					= Color(255,192,203)	--- (255,192,203)
Color.PLUM					= Color(221,160,221)	--- (221,160,221)
Color.POWDERBLUE			= Color(176,224,230)	--- (176,224,230)
Color.PURPLE				= Color(128,0,128)		--- (128,0,128)
Color.RED					= Color(255,0,0)		--- (255,0,0)
Color.ROSYBROWN			= Color(188,143,143)	--- (188,143,143)
Color.ROYALBLUE			= Color(65,105,225)		--- (65,105,225)
Color.SADDLEBROWN			= Color(139,69,19)		--- (139,69,19)
Color.SALMON				= Color(250,128,114)	--- (250,128,114)
Color.SANDYBROWN			= Color(244,164,96)		--- (244,164,96)
Color.SEAGREEN				= Color(46,139,87)		--- (46,139,87)
Color.SEASHELL				= Color(255,245,238)	--- (255,245,238)
Color.SIENNA				= Color(160,82,45)		--- (160,82,45)
Color.SILVER				= Color(192,192,192)	--- (192,192,192)
Color.SKYBLUE				= Color(135,206,235)	--- (135,206,235)
Color.SLATEBLUE			= Color(106,90,205)		--- (106,90,205)
Color.SLATEGRAY			= Color(112,128,144)	--- (112,128,144)
Color.SLATEGREY			= Color(112,128,144)	--- (112,128,144)
Color.SNOW					= Color(255,250,250)	--- (255,250,250)
Color.SPRINGGREEN			= Color(0,255,127)		--- (0,255,127)
Color.STEELBLUE			= Color(70,130,180)		--- (70,130,180)
Color.TAN					= Color(210,180,140)	--- (210,180,140)
Color.TEAL					= Color(0,128,128)		--- (0,128,128)
Color.THISTLE				= Color(216,191,216)	--- (216,191,216)
Color.TOMATO				= Color(255,99,71)		--- (255,99,71)
Color.TURQUOISE			= Color(64,224,208)		--- (64,224,208)
Color.VIOLET				= Color(238,130,238)	--- (238,130,238)
Color.WHEAT					= Color(245,222,179)	--- (245,222,179)
Color.WHITE					= Color(255,255,255)	--- (255,255,255)
Color.WHITESMOKE			= Color(245,245,245)	--- (245,245,245)
Color.YELLOW				= Color(255,255,0)		--- (255,255,0)
Color.YELLOWGREEN			= Color(154,205,50)		--- (154,205,50)
