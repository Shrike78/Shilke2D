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

---constructor
function DrawableObject:init()
	DisplayObj.init(self)

	self._scriptDeck = MOAIScriptDeck.new()
	self._prop:setDeck(self._scriptDeck)
	self._visibleFunc = function() 
			self:_innerDraw() 
		end

	-- by default the object is visible
	self._scriptDeck:setDrawCallback( self._visibleFunc	)
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
Wraps the MOAIGfxDevice.setPenColor call handleing alpha mode (premultiplied or straight alpha)
The following calls are valid:
- setColor(r,g,b)
- setColor(r,g,b,a)
- setColor("#FFFFFF")
- setColor("#FFFFFFFF")
- setColor(Color)
@param r red value [0,255] or a Color or hex string
@param g green value [0,255] or nil
@param b blue value [0,255] or nil
@param a alpha value [0,255] or nil
--]]
function DrawableObject:setPenColor(r,g,b,a)
	local r,g,b,a = Color._paramConversion(r,g,b,a)
	local ignoreAlphaMode = forceStraightAlpha == true
	if a~=1 and self:hasPremultipliedAlpha() then
		r,g,b = r*a, g*a, b*a
	end
	MOAIGfxDevice.setPenColor(r,g,b,a)
end

--[[---
Called each frame, contains specific object draw calls.
Registered drawCallback of the scriptDeck object.
Objects that inherits from this class must override this method.
--]]
function DrawableObject:_innerDraw()
	error("DrawableObject:draw must be overridden")
end
