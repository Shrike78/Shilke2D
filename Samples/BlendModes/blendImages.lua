--[[
The sample is based on http://www.andersriggelsen.dk/glblendfunc.php example

Graphics from www.interfacelift.com:
http://interfacelift.com/wallpaper/details/2262/flamingos.html
--]]

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

local bg_name 		= "flamingobg.jpg"
local fg_name 		= "flamingos.png"

function createSample(bkgLayer, fgLayer, bkgTexture, fgTexture, pma, description, pivotMode, posX, posY)
	
	--scale objects
	local s = .8
	
	local bkgImg = Image(bkgTexture, pivotMode)
	bkgImg:setPosition(posX, posY)
	bkgImg:setScale(s,s)
	bkgLayer:addChild(bkgImg)
	
	local fgImg = Image(fgTexture, pivotMode)
	fgImg:setPosition(posX, posY)
	fgImg:setPremultipliedAlpha(pma)
	fgImg:setScale(s,s)
	fgLayer:addChild(fgImg)
	
	local bkh = bkgImg:getHeight(bkgLayer)
	local txt = TextField(300, 30, description, nil, 12, pivotMode)
	local px = posX == 0 and 0 or WIDTH
	local py = posY == 0 and bkh or HEIGHT - bkh
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
	
	local bkgTexture = Texture.fromFile(bg_name)
	local fgImage = BitmapData.fromFile(fg_name, ColorTransform.NONE)
	
	createSample(bkgLayer, fgLayer, bkgTexture, Texture(fgImage), false, "default", 
		PivotMode.TOP_LEFT, 0, 0)
	
	BitmapData.setTransparentColor(fgImage, Color.BLACK)
	
	createSample(bkgLayer, fgLayer, bkgTexture, Texture(fgImage), false, "black transparent pixels", 
		PivotMode.TOP_RIGHT, WIDTH, 0)
	
	BitmapData.setTransparentColor(fgImage, Color.WHITE)
	createSample(bkgLayer, fgLayer, bkgTexture, Texture(fgImage), false, "white transparent pixels", 
		PivotMode.BOTTOM_LEFT, 0, HEIGHT)
	
	
	BitmapData.premultiplyAlpha(fgImage)
	createSample(bkgLayer, fgLayer, bkgTexture, Texture(fgImage), true, 
		"Premultiplied alpha",	PivotMode.BOTTOM_RIGHT,WIDTH, HEIGHT)
	
	
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
