__DEBUG_CALLBACKS__ = true
--__USE_SIMULATION_COORDS__ = true

require("Shilke2D/include")

IO.setWorkingDir("Assets/BlendModes")

local WIDTH,HEIGHT = 1024,768
local FPS = 60

local blendModes = BlendMode.getRegisteredModes(true)
local blendModeIdx = 1
local infoTxt
local fgLayer


local QuadDrawObj = class(DrawableObject)

function QuadDrawObj:init(w,h,color)
	DrawableObject.init(self)
	self._w = w
	self._h = h
	self._c = color
end

function QuadDrawObj:getRect(resultRect)
	local r = Rect() or resultRect
	r:set(0,0,self._w, self._h)
	return r
end

function QuadDrawObj:_innerDraw()
	self:setPenColor(self._c)
	MOAIDraw.fillRect(0,0,self._w,self._h)
end

function createSample(bkgLayer, fgLayer, color, pma, description, pivotMode, posX, posY)
	
	--scale objects
	local s = .8
	
	local qback = Quad(400,400, pivotMode)
	qback:setColor(0,150,200)
	qback:setPosition(posX, posY)
	qback:setScale(s,s)
	bkgLayer:addChild(qback)
	
	local bkw, bkh = qback:getSize(bkgLayer)
	
	local q = QuadDrawObj(200,200, color)
	q:setScale(s,s)
	fgLayer:addChild(q)
	
	local qw, qh = q:getSize(fgLayer)
	
	local px = posX == 0 and bkw/2 - qw/2 or WIDTH - bkw/2 - qw/2 
	local py = posY == 0 and bkh/2 - qh/2 or HEIGHT - bkh/2 - qh/2
	
	q:setPosition(px, py)
	q:setPremultipliedAlpha(pma)
	
	local txt = TextField(300, 30, description, nil, 12, pivotMode)
	px = posX == 0 and 0 or WIDTH
	py = posY == 0 and bkh or HEIGHT - bkh
	txt:setPosition(px, py)
	txt:setHAlignment(TextField.CENTER_JUSTIFY)
	bkgLayer:addChild(txt)
	
end

function setup()
	Shilke2D.current:showStats(true)
	stage = Shilke2D.current.stage
	
	local bkgLayer = DisplayObjContainer()
	fgLayer = DisplayObjContainer()
	stage:addChild(bkgLayer)
	stage:addChild(fgLayer)
	
	createSample(bkgLayer, fgLayer, Color(255,255,255,128), false,
		"straight white (a=128)",	PivotMode.TOP_LEFT, 	0, 0)
	
	createSample(bkgLayer, fgLayer, Color(255,255,255,128), true,
		"pma white (a=128)",	PivotMode.TOP_RIGHT, 		WIDTH, 0)
	
	createSample(bkgLayer, fgLayer, Color(0,0,0,128), false,
		"straight black (a=128)",	PivotMode.BOTTOM_LEFT, 0, HEIGHT)
	
	createSample(bkgLayer, fgLayer, Color(0,0,0,128), true,
		"pma black (a=128)",	PivotMode.BOTTOM_RIGHT,	WIDTH, HEIGHT)
	
	infoTxt = TextField(500, 30, "Press A/Z to switch blend mode: " .. blendModes[blendModeIdx], nil, 20, PivotMode.CENTER)
	infoTxt:setPosition(WIDTH/2, HEIGHT/2)
	infoTxt:setAlignment(TextField.CENTER_JUSTIFY, TextField.CENTER_JUSTIFY)
	stage:addChild(infoTxt)
	
end

function update()
end

function touched(touch)
end

function updateBlendMode()
	local bmName = blendModes[blendModeIdx]
	infoTxt:setText("Press A/Z to switch blend mode: " .. bmName)
	for obj in children(fgLayer) do
		obj:setBlendMode(bmName)
	end
end

function onKeyboardEvent(key, down)
	if down then
		if key == KEY('z') or key == KEY('Z') then
			blendModeIdx = blendModeIdx ~= 1 and (blendModeIdx - 1) or #blendModes
			updateBlendMode()
		elseif key == KEY('a') or key == KEY('A') then
			blendModeIdx = (blendModeIdx ~= #blendModes) and (blendModeIdx + 1) or 1
			updateBlendMode()
		end
		
	end
end

shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()
