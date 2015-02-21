--[[---
A DrawableObj is a displayObj that implements MOAIScriptDeck, allowing vectorial drawing.
It's an abstract class, in fact it doesn't implements the getRect() method, and it's the base class of 
all the object that support vectorial drawing.

Concrete objects that inherits from this class need to implements the DisplayObj:getRect() method and
the new DrawableObj:_innerDraw()

BlendModes / Alpha mode

DrawableObj by default are set with premultiplied alpha. 
The setColor method (inherited from DisplayObj) works as expected, but a particolar logic 
must be checked with setPen call in innerdraw callbacks. The setPen completely override
all the prop and parent color properties, and premultiplied alpha logic must be handled manually.
Future development should provide a wrapped logic for all the MOAIDraw calls and for MOAIGfxDevice
pen handling
--]]
DrawableObj = class(DisplayObj)


---
-- Create a DrawableObj subclass starting from a draw function and a rect definition
-- @tparam function drawFunc the function used to draw
-- @tparam int width
-- @tparam int height
-- @tparam[opt=0] int x
-- @tparam[opt=0] int y
-- @treturn class class(DrawableObj)
function DrawableObj.fromDrawFunction(drawFunc, width, height, x, y)
	local x = x or 0
	local y = y or 0
	local T = class(DrawableObj)
	
	function T:init()
		DrawableObj.init(self)
	end
	
	function T:getRect(r)
		local res = r or Rect()
		res.x = x
		res.y = y
		res.w = width
		res.h = height 
		return res
	end
	
	function T:_innerDraw()
		drawFunc()
	end
	
	return T
end

---
-- Constructor
function DrawableObj:init()
	DisplayObj.init(self)
	self._scriptDeck = MOAIScriptDeck.new()
	self._prop:setDeck(self._scriptDeck)
	local cbFunc = function() self:_innerDraw() end
	if __DEBUG_CALLBACKS__ then
		self._scriptDeck:setDrawCallback( function()
				pcall(function() require('mobdebug').on() end )
				self:_innerDraw() 
				self._scriptDeck:setDrawCallback( cbFunc )
			end
		)
	else
		self._scriptDeck:setDrawCallback( cbFunc )
	end
end

---
-- Override DisplayObj method to implement a specific visibility logic.
-- When the object is set as not visible the scriptDeck is removed from MOAIProp
-- @param visible boolean value
function DrawableObj:setVisible(visible)
	DisplayObj.setVisible(self, visible)
	if visible then
		self._prop:setDeck(self._scriptDeck)
	else
		self._prop:setDeck(nil)
	end
end

---
-- Calls the Graphics.setPenColor forcing to use the alpha mode
-- accordingly to displayObj configuration. After it restores original
-- alpha mode
-- @param r red value [0,255] or a Color or hex string or int32 color
-- @param g green value [0,255] or nil
-- @param b blue value [0,255] or nil
-- @param a alpha value [0,255] or nil
function DrawableObj:setPenColor(r,g,b,a)
	-- use a direct implementation avoiding to rely on Graphics
	-- more performant and anyway detatched from global Graphics setup
	local r,g,b,a = Color._toNormalizedRGBA(r,g,b,a)
	if self:hasPremultipliedAlpha() and a ~= 1 then
		r,g,b = r*a, g*a, b*a
	end
	MOAIGfxDevice.setPenColor(r,g,b,a)
end

---
-- Called each frame, contains specific object draw calls.
-- Registered drawCallback of the scriptDeck object.
-- Objects that inherits from this class must override this method.
function DrawableObj:_innerDraw()
	error("DrawableObj:draw must be overridden")
end
