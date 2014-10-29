--[[---
A DrawableObject is a displayObj that implements MOAIScriptDeck, allowing vectorial drawing.
It's an abstract class, in fact it doesn't implements the getRect() method, and it's the base class of 
all the object that support vectorial drawing.

Concrete objects that inherits from this class need to implements the DisplayObj:getRect() method and
the new DrawableObject:_innerDraw()

BlendModes / Alpha mode

DrawableObject by default are set with premultiplied alpha. 
The setColor method (inherited from DisplayObj) works as expected, but a particolar logic 
must be checked with setPen call in innerdraw callbacks. The setPen completely override
all the prop and parent color properties, and premultiplied alpha logic must be handled manually.
Future development should provide a wrapped logic for all the MOAIDraw calls and for MOAIGfxDevice
pen handling
--]]
DrawableObject = class(DisplayObj)


--[[---
Create a DrawableObj starting from a draw function and a rect definition
@tparam function drawFunc the function used to draw
@tparam int width
@tparam int height
@tparam[opt=0] int x
@tparam[opt=0] int y
@treturn DrawableObject
--]]
function DrawableObject.fromDrawFunction(drawFunc, width, height, x, y)
	local obj = DrawableObject()
	local x = x or 0
	local y = y or 0
	obj.getRect = function(o,r)
		local res = r or Rect()
		res:set(x,y,width,height)
		return res
	end
	obj._innerDraw = function(o)
		drawFunc()
	end
	return obj
end

---constructor
function DrawableObject:init()
	DisplayObj.init(self)
	self._scriptDeck = MOAIScriptDeck.new()
	self._prop:setDeck(self._scriptDeck)
	self._scriptDeck:setDrawCallback( function()
			self:_innerDraw() 
		end
	)
end

--[[---
Override DisplayObj method to implement a specific visibility logic.
When the object is set as not visible the scriptDeck is removed from MOAIProp
@param visible boolean value
--]]
function DrawableObject:setVisible(visible)
	if self._visible ~= visible then
		self._visible = visible 
		if visible then
			self._prop:setDeck(self._scriptDeck)
		else
			self._prop:setDeck(nil)
		end
	end
end

--[[---
Calls the Graphics.setPenColor forcing to use the alpha mode
accordingly to displayObj configuration. After it restores original
alpha mode
@param r red value [0,255] or a Color or hex string
@param g green value [0,255] or nil
@param b blue value [0,255] or nil
@param a alpha value [0,255] or nil
--]]
function DrawableObject:setPenColor(r,g,b,a)
	local pmaEnabled = Graphics.hasPremultipliedAlpha()
	Graphics.setPremultipliedAlpha(self:hasPremultipliedAlpha())
	Graphics.setPenColor(r,g,b,a)
	Graphics.setPremultipliedAlpha(pmaEnabled)
end

--[[---
Called each frame, contains specific object draw calls.
Registered drawCallback of the scriptDeck object.
Objects that inherits from this class must override this method.
--]]
function DrawableObject:_innerDraw()
	error("DrawableObject:draw must be overridden")
end
