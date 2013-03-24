--[[---
A DrawableObject is a displayObj that implements MOAIScriptDeck, so that allows vectorial drawing.
It's an abstract class, in fact it doesn't implements the getRect() method, and is the base class of 
all the object that make vectorial drawing.

Concrete objects that inherits from this class need to implements the DisplayObj:getRect() method and
the new DrawableObject:_innerDraw()
--]]
DrawableObject = class(DisplayObj)

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

---Override DisplayObj method to implement a specific visibility logic.
--When the object is set as not visible the scriptDeck is removed from MOAIProp
--@param visible boolean value
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

---Called each frame, contains specific object draw calls.
--Registered drawCallback of the scriptDeck object.
--Objects that inherits from this class must override this method.
function DrawableObject:_innerDraw()
	error("DrawableObject:draw must be overridden")
end
