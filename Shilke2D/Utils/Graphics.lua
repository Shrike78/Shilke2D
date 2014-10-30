--[[---
Namespace containing all the functions related to vectorial draw.
It wraps MOAIGfxDevice setters and all the MOAIDraw functions
It also add support for premultiplied alpha logic and Shilke2D Colors
--]]
Graphics = {}

local _pmaModeOn = true

---check if the premultiplied alpha mode is enabled
--@treturn bool
function Graphics.hasPremultipliedAlpha()
	return _pmaModeOn
end

---enable/disable premuplitplied alpha mode
--@tparam[opt=true] bool enabled
function Graphics.setPremultipliedAlpha(enabled)
	local enabled = enabled ~= false
	_pmaModeOn = enabled
end

--[[---
Wraps MOAIGfxDevice.setPenColor, handling Shilke2D Color object and 
premultiplied alpha mode
@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
--]]
function Graphics.setPenColor(r,g,b,a)
	local r,g,b,a = Color._toNormalizedRGBA(r,g,b,a)
	if _pmaModeOn and a ~= 1 then
		r, g, b = r*a, g*a, b*a
	end
	MOAIGfxDevice.setPenColor(r,g,b,a)
end


--[[---
@function Graphics.setPenWidth
@tparam number width
--]]
Graphics.setPenWidth = MOAIGfxDevice.setPenWidth

--[[---
@function Graphics.setPointSize
@tparam number size
--]]
Graphics.setPointSize = MOAIGfxDevice.setPointSize

--[[---
Draw a box outline.
@function Graphics.drawBoxOutline
@tparam number x0
@tparam number y0
@tparam number z0
@tparam number x1
@tparam number y1
@tparam number z1
--]]
Graphics.drawBoxOutline = MOAIDraw.drawBoxOutline

--[[---
Draw a circle.
@function Graphics.drawCircle
@tparam number x
@tparam number y
@tparam number r
@tparam number steps
--]]
Graphics.drawCircle = MOAIDraw.drawCircle

--[[---
Draw an ellipse.
@function Graphics.drawEllipse
@tparam number x
@tparam number y
@tparam number xRad
@tparam number yRad
@tparam number steps
--]]
Graphics.drawEllipse = MOAIDraw.drawEllipse

--[[---
Draw a line.
@function Graphics.drawLine
@param {...} List of vertices (x, y) or an array of vertices { x0, y0, ... , xn, yn }
--]]
Graphics.drawLine = MOAIDraw.drawLine
 
--[[---
Draw a list of points.
@function Graphics.drawPoints
@param {...} List of vertices (x, y) or an array of vertices { x0, y0, ... , xn, yn }
--]]
Graphics.drawPoints = MOAIDraw.drawPoints

--[[---
Draw a ray.
@function Graphics.drawRay
@tparam number x
@tparam number y
@tparam number dx
@tparam number dy
--]]
Graphics.drawRay = MOAIDraw.drawRay

--[[---
Draw a rectangle.
@function Graphics.drawRect
@tparam number x0
@tparam number y0
@tparam number x1
@tparam number y1
--]]
Graphics.drawRect = MOAIDraw.drawRect

--[[---
Draw a filled circle.
@function Graphics.fillCircle
@tparam number x
@tparam number y
@tparam number r
@tparam number steps
--]]
Graphics.fillCircle = MOAIDraw.fillCircle

--[[---
Draw a filled ellipse.
@function Graphics.fillEllipse
@tparam number x
@tparam number y
@tparam number xRad
@tparam number yRad
@tparam number steps
--]]
Graphics.fillEllipse = MOAIDraw.fillEllipse

--[[---
Draw a filled fan.
@function Graphics.fillFan
@param {...} List of vertices (x, y) or an array of vertices { x0, y0, ... , xn, yn }
--]]
Graphics.fillFan = MOAIDraw.fillFan

--[[---
Draw a filled rectangle.
@function Graphics.fillRect
@tparam number x0
@tparam number y0
@tparam number x1
@tparam number y1
--]]
Graphics.fillRect = MOAIDraw.fillRect
