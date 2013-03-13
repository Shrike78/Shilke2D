--DrawableObject 

DrawableObject = class(DisplayObj)

function DrawableObject:init()
    DisplayObj.init(self)
	
	self._scriptDeck = MOAIScriptDeck.new()
	self._prop:setDeck(self._scriptDeck)
    self._visibleFunc = function(index, xOff, yOff, xScale, yScale) 
			self:_innerDraw(index, xOff, yOff, xScale, yScale) 
		end
	
	-- by default the object is visible
    self._scriptDeck:setDrawCallback( self._visibleFunc	)
end

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

function DrawableObject:_innerDraw(index, xOff, yOff, xScale, yScale)
	error("DrawableObject:draw must be overridden")
end
