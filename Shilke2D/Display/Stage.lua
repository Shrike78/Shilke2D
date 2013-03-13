-- Stage

Stage = class(DisplayObjContainer)

function Stage:init(viewport)
	DisplayObjContainer.init(self)
    self._prop:setViewport(viewport)
    
    self._debugDeck = MOAIScriptDeck.new ()
    --self._debugDeck:setRect ( -64, -64, 64, 64 )
    self._debugDeck:setDrawCallback ( function()
			if self._showAABounds then
				self:drawAABounds(false)
			end
			if self._showOrientedBounds then
				self:drawOrientedBounds()
			end
		end
	)

    self._debugProp = MOAIProp.new ()
    self._debugProp:setDeck ( self._debugDeck )
    
    self._rt = {self._renderTable}
end

--Stage is a Layer not a 'generic' prop like ALL the others displayObjs
function Stage:_createProp()
    return MOAILayer.new()
end

function Stage:showDebugLines(showOrientedBounds,showAABounds)
	local showDebug = showOrientedBounds or showAABounds
	
	self._showOrientedBounds = showOrientedBounds
	self._showAABounds = showAABounds
	
	if showDebug and not self._rt[2] then
		self._rt[2] = self._debugProp
	end
	if not showDebug and self._rt[2] then
		self._rt[2] = nil
	end
end

function Stage:setBackground(r,g,b)
	if class_type(r) == Color then
		MOAIGfxDevice.getFrameBuffer():setClearColor(r:unpack_normalized())
	else
		MOAIGfxDevice.getFrameBuffer():setClearColor(r/255,g/255,b/255,1)
	end
end

--the method is called by a DisplayObjContainer when the DisplayObj is
--added as child
function Stage:_setParent(parent)
    error("Stage cannot be child of another DisplayObjContainer")
end

function Stage:setPivot(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setPivotX(x)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setPivotY(y)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setPosition(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setPosition_v2(v)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setPositionX(x)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setPositionY(y)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:translate(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

-- rotation angle is expressed in radians
function Stage:setRotation(r)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setScale(x,y)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setScale_v2(v)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setScaleX(s)
    error("It's not possible to set geometric properties of a Stage")
end

function Stage:setScaleY(s)
    error("It's not possible to set geometric properties of a Stage")
end
