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
	self.r, self.g, self.b, self.a = Color._toRGBA(r, g, b, a)
end

---Returns the 4 components
--@treturn number r (0,255)
--@treturn number g (0,255)
--@treturn number b (0,255)
--@treturn number a (0,255)
function Color:unpack()
	return self.r, self.g, self.b, self.a
end
	
---Returns the 4 components normalized
--@treturn number r (0,1)
--@treturn number g (0,1)
--@treturn number b (0,1)
--@treturn number a (0,1)
function Color:unpack_normalized()
	local r,g,b,a = self:unpack()
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
	--can result in a 'negative' color. accepted only to support particular algebrical operation, like for tweening.
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
--@tparam[opt=255] int a (0,255)
--@treturn int
function Color.rgba2int(r,g,b,a)
	local a = a or 255
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


--[[---
convert an hex color string (that can start or not with #) to r,g,b,a (0,255) values 
@tparam string hex string defining color
@treturn int r (0,255)
@treturn int g (0,255)
@treturn int b (0,255)
@treturn int a v if the hex string doesn't contains alpha info it returns 255
--]]
function Color.hexstr2rgba(hex)
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
convert an r,g,b color set into an hex color string
@tparam int r (0,255)
@tparam int g (0,255)
@tparam int b (0,255)
@tparam[opt=nil] int a (0,255)
@treturn string hex string in format #rrggbb or #rrggbbaa
--]]
function Color.rgba2hexstr(r,g,b,a)
	if a then 
		return string.format('#%02x%02x%02x%02x',r,g,b,a)
	else
		return string.format('#%02x%02x%02x',r,g,b)
	end
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
Utility function. 
It accepts as input a color expressed in all supported formats:

- (0,255) rgb or rgba values
- int32 color value) and returns the 
- hex string 
- Color object

and returns the (0,255) r,g,b,a values

@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
@return r (0,255)
@return g (0,255)
@return b (0,255)
@return a (0,255)
--]]
function Color._toRGBA(r, g, b, a)
	local t = class_type(r)
	if t == 'number' then
		if g then
			return r, g, b, (a or 255)
		else
			return Color.int2rgba(r)
		end
	elseif t == Color then
		return r:unpack()
	elseif t == 'string' then
		return Color.hexstr2rgba(r)
	end
	error("no suitable conversion of this parameters")
end


--[[---
Utility function. 
It accepts as input a color expressed in all supported formats:

- (0,255) rgb or rgba values
- int32 color value) and returns the 
- hex string 
- Color object

and returns the normalized (0,1) r,g,b,a values

@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
@return r (0,1)
@return g (0,1)
@return b (0,1)
@return a (0,1)
--]]		   
function Color._toNormalizedRGBA(r,g,b,a)
	local _r,_g,_b,_a = Color._toRGBA(r,g,b,a)
	return _r * INV_255, _g * INV_255, _b * INV_255, _a * INV_255			
end



--- (240,248,255)
Color.ALICEBLUE				= Color.rgba2int(240,248,255)	
--- (250,235,215)
Color.ANTIQUEWHITE			= Color.rgba2int(250,235,215)	
--- (0,255,255)
Color.AQUA					= Color.rgba2int(0,255,255)	
--- (127,255,212)
Color.AQUAMARINE			= Color.rgba2int(127,255,212)	
--- (240,255,255)
Color.AZURE					= Color.rgba2int(240,255,255)	
--- (245,245,220)
Color.BEIGE					= Color.rgba2int(245,245,220)	
--- (255,228,196)
Color.BISQUE				= Color.rgba2int(255,228,196)	
--- (0,0,0)
Color.BLACK					= Color.rgba2int(0,0,0)		
--- (255,235,205)
Color.BLANCHEDALMOND		= Color.rgba2int(255,235,205)	
--- (0,0,255)
Color.BLUE					= Color.rgba2int(0,0,255)		
--- (138,43,226)
Color.BLUEVIOLET			= Color.rgba2int(138,43,226)	
--- (165,42,42)
Color.BROWN					= Color.rgba2int(165,42,42)	
--- (222,184,135)
Color.BURLYWOOD				= Color.rgba2int(222,184,135)	
--- (95,158,160)
Color.CADETBLUE				= Color.rgba2int(95,158,160)	
--- (127,255,0)
Color.CHARTREUSE			= Color.rgba2int(127,255,0)	
--- (210,105,30)
Color.CHOCOLATE				= Color.rgba2int(210,105,30)	
--- (255,127,80)
Color.CORAL					= Color.rgba2int(255,127,80)	
--- (100,149,237)
Color.CORNFLOWERBLUE		= Color.rgba2int(100,149,237)	
--- (255,248,220)
Color.CORNSILK				= Color.rgba2int(255,248,220)	
--- (220,20,60)
Color.CRIMSON				= Color.rgba2int(220,20,60)	
--- (0,255,255)
Color.CYAN					= Color.rgba2int(0,255,255)	
--- (0,0,139)
Color.DARKBLUE				= Color.rgba2int(0,0,139)		
--- (0,139,139)
Color.DARKCYAN				= Color.rgba2int(0,139,139)	
--- (184,134,11)
Color.DARKGOLDENROD			= Color.rgba2int(184,134,11)	
--- (169,169,169)
Color.DARKGRAY				= Color.rgba2int(169,169,169)	
--- (169,169,169)
Color.DARKGREY				= Color.DARKGRAY				
--- (0,100,0)
Color.DARKGREEN				= Color.rgba2int(0,100,0)		
--- (189,183,107)
Color.DARKKHAKI				= Color.rgba2int(189,183,107)	
--- (139,0,139)
Color.DARKMAGENTA			= Color.rgba2int(139,0,139)	
--- (85,107,47)
Color.DARKOLIVEGREEN		= Color.rgba2int(85,107,47)	
--- (255,140,0)
Color.DARKORANGE			= Color.rgba2int(255,140,0)	
--- (153,50,204)
Color.DARKORCHID			= Color.rgba2int(153,50,204)	
--- (139,0,0)
Color.DARKRED				= Color.rgba2int(139,0,0)		
--- (233,150,122)
Color.DARKSALMON			= Color.rgba2int(233,150,122)	
--- (143,188,143)
Color.DARKSEAGREEN			= Color.rgba2int(143,188,143)	
--- (72,61,139)
Color.DARKSLATEBLUE			= Color.rgba2int(72,61,139)	
--- (47,79,79)
Color.DARKSLATEGRAY			= Color.rgba2int(47,79,79)		
--- (47,79,79)
Color.DARKSLATEGREY			= Color.DARKSLATEGRAY			
--- (0,206,209)
Color.DARKTURQUOISE			= Color.rgba2int(0,206,209)	
--- (148,0,211)
Color.DARKVIOLET			= Color.rgba2int(148,0,211)	
--- (255,20,147)
Color.DEEPPINK				= Color.rgba2int(255,20,147)	
--- (0,191,255)
Color.DEEPSKYBLUE			= Color.rgba2int(0,191,255)	
--- (105,105,105)
Color.DIMGRAY				= Color.rgba2int(105,105,105)	
--- (105,105,105)
Color.DIMGREY				= Color.DIMGRAY					
--- (30,144,255)
Color.DODGERBLUE			= Color.rgba2int(30,144,255)	
--- (178,34,34)
Color.FIREBRICK				= Color.rgba2int(178,34,34)	
--- (255,250,240)
Color.FLORALWHITE			= Color.rgba2int(255,250,240)	
--- (34,139,34)
Color.FORESTGREEN			= Color.rgba2int(34,139,34)	
--- (255,0,255)
Color.FUCHSIA				= Color.rgba2int(255,0,255)	
--- (220,220,220)
Color.GAINSBORO				= Color.rgba2int(220,220,220)	
--- (248,248,255)
Color.GHOSTWHITE			= Color.rgba2int(248,248,255)	
--- (255,215,0)
Color.GOLD					= Color.rgba2int(255,215,0)	
--- (218,165,32)
Color.GOLDENROD				= Color.rgba2int(218,165,32) 	
--- (128,128,128)
Color.GRAY					= Color.rgba2int(128,128,128)	
--- (128,128,128)
Color.GREY					= Color.GRAY
--- (0,128,0)
Color.GREEN					= Color.rgba2int(0,128,0)		
--- (173,255,47)
Color.GREENYELLOW			= Color.rgba2int(173,255,47)	
--- (240,255,240)
Color.HONEYDEW				= Color.rgba2int(240,255,240)	
--- (255,105,180)
Color.HOTPINK				= Color.rgba2int(255,105,180)	
--- (205,92,92)
Color.INDIANRED				= Color.rgba2int(205,92,92)	
--- (75,0,130)
Color.INDIGO				= Color.rgba2int(75,0,130)		
--- (255,255,240)
Color.IVORY					= Color.rgba2int(255,255,240)	
--- (240,230,140)
Color.KHAKI					= Color.rgba2int(240,230,140)	
--- (230,230,250)
Color.LAVENDER				= Color.rgba2int(230,230,250)	
--- (255,240,245)
Color.LAVENDERBLUSH			= Color.rgba2int(255,240,245)	
--- (124,252,0)
Color.LAWNGREEN				= Color.rgba2int(124,252,0)	
--- (255,250,205)
Color.LEMONCHIFFON			= Color.rgba2int(255,250,205)	
--- (173,216,230)
Color.LIGHTBLUE				= Color.rgba2int(173,216,230)	
--- (240,128,128)
Color.LIGHTCORAL			= Color.rgba2int(240,128,128)	
--- (224,255,255)
Color.LIGHTCYAN				= Color.rgba2int(224,255,255)	
--- (250,250,210)
Color.LIGHTGOLDENRODYELLOW	= Color.rgba2int(250,250,210)	
--- (211,211,211)
Color.LIGHTGRAY				= Color.rgba2int(211,211,211)	
--- (211,211,211)
Color.LIGHTGREY				= Color.LIGHTGRAY				
--- (144,238,144)
Color.LIGHTGREEN			= Color.rgba2int(144,238,144)	
--- (255,182,193)
Color.LIGHTPINK				= Color.rgba2int(255,182,193)	
--- (255,160,122)
Color.LIGHTSALMON			= Color.rgba2int(255,160,122)	
--- (32,178,170)
Color.LIGHTSEAGREEN			= Color.rgba2int(32,178,170) 	
--- (135,206,250)
Color.LIGHTSKYBLUE			= Color.rgba2int(135,206,250)	
--- (119,136,153)
Color.LIGHTSLATEGRAY		= Color.rgba2int(119,136,153)	
--- (119,136,153)
Color.LIGHTSLATEGREY		= Color.LIGHTSLATEGRAY			
--- (176,196,222)
Color.LIGHTSTEELBLUE		= Color.rgba2int(176,196,222)	
--- (255,255,224)
Color.LIGHTYELLOW			= Color.rgba2int(255,255,224)	
--- (0,255,0)
Color.LIME					= Color.rgba2int(0,255,0)		
--- (50,205,50)
Color.LIMEGREEN				= Color.rgba2int(50,205,50)	
--- (250,240,230)
Color.LINEN					= Color.rgba2int(250,240,230)	
--- (255,0,255)
Color.MAGENTA				= Color.rgba2int(255,0,255)	
--- (128,0,0)
Color.MAROON				= Color.rgba2int(128,0,0)		
--- (102,205,170)
Color.MEDIUMAQUAMARINE		= Color.rgba2int(102,205,170)	
--- (0,0,205)
Color.MEDIUMBLUE			= Color.rgba2int(0,0,205)		
--- (186,85,211)
Color.MEDIUMORCHID			= Color.rgba2int(186,85,211)	
--- (147,112,219)
Color.MEDIUMPURPLE			= Color.rgba2int(147,112,219)	
--- (60,179,113)
Color.MEDIUMSEAGREEN		= Color.rgba2int(60,179,113)	
--- (123,104,238)
Color.MEDIUMSLATEBLUE		= Color.rgba2int(123,104,238) 	
--- (0,250,154)
Color.MEDIUMSPRINGGREEN		= Color.rgba2int(0,250,154) 	
--- (72,209,204)
Color.MEDIUMTURQUOISE		= Color.rgba2int(72,209,204)	
--- (199,21,133)
Color.MEDIUMVIOLETRED		= Color.rgba2int(199,21,133)	
--- (25,25,112)
Color.MIDNIGHTBLUE			= Color.rgba2int(25,25,112)	
--- (245,255,250)
Color.MINTCREAM				= Color.rgba2int(245,255,250)	
--- (255,228,225)
Color.MISTYROSE				= Color.rgba2int(255,228,225)	
--- (255,228,181)
Color.MOCCASIN				= Color.rgba2int(255,228,181)	
--- (255,222,173)
Color.NAVAJOWHITE			= Color.rgba2int(255,222,173)	
--- (0,0,128)
Color.NAVY					= Color.rgba2int(0,0,128)		
--- (253,245,230)
Color.OLDLACE				= Color.rgba2int(253,245,230)	
--- (128,128,0)
Color.OLIVE					= Color.rgba2int(128,128,0)	
--- (107,142,35)
Color.OLIVEDRAB				= Color.rgba2int(107,142,35)	
--- (255,165,0)
Color.ORANGE				= Color.rgba2int(255,165,0)	
--- (255,69,0)
Color.ORANGERED				= Color.rgba2int(255,69,0)		
--- (218,112,214)
Color.ORCHID				= Color.rgba2int(218,112,214)	
--- (238,232,170)
Color.PALEGOLDENROD			= Color.rgba2int(238,232,170)	
--- (152,251,152)
Color.PALEGREEN				= Color.rgba2int(152,251,152)	
--- (175,238,238)
Color.PALETURQUOISE			= Color.rgba2int(175,238,238)	
--- (219,112,147)
Color.PALEVIOLETRED			= Color.rgba2int(219,112,147)	
--- (255,239,213)
Color.PAPAYAWHIP			= Color.rgba2int(255,239,213)	
--- (255,218,185)
Color.PEACHPUFF				= Color.rgba2int(255,218,185)	
--- (205,133,63)
Color.PERU					= Color.rgba2int(205,133,63)	
--- (255,192,203)
Color.PINK					= Color.rgba2int(255,192,203)	
--- (221,160,221)
Color.PLUM					= Color.rgba2int(221,160,221)	
--- (176,224,230)
Color.POWDERBLUE			= Color.rgba2int(176,224,230)	
--- (128,0,128)
Color.PURPLE				= Color.rgba2int(128,0,128)	
--- (255,0,0)
Color.RED					= Color.rgba2int(255,0,0)		
--- (188,143,143)
Color.ROSYBROWN				= Color.rgba2int(188,143,143)	
--- (65,105,225)
Color.ROYALBLUE				= Color.rgba2int(65,105,225)	
--- (139,69,19)
Color.SADDLEBROWN			= Color.rgba2int(139,69,19)	
--- (250,128,114)
Color.SALMON				= Color.rgba2int(250,128,114)	
--- (244,164,96)
Color.SANDYBROWN			= Color.rgba2int(244,164,96)	
--- (46,139,87)
Color.SEAGREEN				= Color.rgba2int(46,139,87)	
--- (255,245,238)
Color.SEASHELL				= Color.rgba2int(255,245,238)	
--- (160,82,45)
Color.SIENNA				= Color.rgba2int(160,82,45)	
--- (192,192,192)
Color.SILVER				= Color.rgba2int(192,192,192)	
--- (135,206,235)
Color.SKYBLUE				= Color.rgba2int(135,206,235)	
--- (106,90,205)
Color.SLATEBLUE				= Color.rgba2int(106,90,205)	
--- (112,128,144)
Color.SLATEGRAY				= Color.rgba2int(112,128,144)	
--- (112,128,144)
Color.SLATEGREY				= Color.SLATEGRAY				
--- (255,250,250)
Color.SNOW					= Color.rgba2int(255,250,250)	
--- (0,255,127)
Color.SPRINGGREEN			= Color.rgba2int(0,255,127)	
--- (70,130,180)
Color.STEELBLUE				= Color.rgba2int(70,130,180)	
--- (210,180,140)
Color.TAN					= Color.rgba2int(210,180,140)	
--- (0,128,128)
Color.TEAL					= Color.rgba2int(0,128,128)	
--- (216,191,216)
Color.THISTLE				= Color.rgba2int(216,191,216)	
--- (255,99,71)
Color.TOMATO				= Color.rgba2int(255,99,71)	
--- (64,224,208)
Color.TURQUOISE				= Color.rgba2int(64,224,208)	
--- (238,130,238)
Color.VIOLET				= Color.rgba2int(238,130,238)	
--- (245,222,179)
Color.WHEAT					= Color.rgba2int(245,222,179)	
--- (255,255,255)
Color.WHITE					= Color.rgba2int(255,255,255)	
--- (245,245,245)
Color.WHITESMOKE			= Color.rgba2int(245,245,245)	
--- (255,255,0)
Color.YELLOW				= Color.rgba2int(255,255,0)	
--- (154,205,50)
Color.YELLOWGREEN			= Color.rgba2int(154,205,50)