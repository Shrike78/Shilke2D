-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
__DEBUG_CALLBACKS__ = false

--By default (0,0) is topleft point and y is from top to bottom. Defining this allows to 
--set (0,0) as bottomleft point and having y from bottom to top.
--__USE_SIMULATION_COORDS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets")


--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	
    local shilke = Shilke2D.current
	
	--the stage is the base displayObjContainer of the scene. Everything need to be connected to the
	--stage to be displayed. The stage is a particular displayObjContainer because it can't be moved,scaled
	--or anyway transformed geometrically.
	local stage = shilke.stage 
	
	--show as overlay fps and memory allocation
	shilke:showStats(true)
    
    --if not set, the default color is (0,0,0,255)
    stage:setBackground(128,128,128)
	
	--it's possible to load an image and automatically create sub regions if the regions
	--have all the same size and the margin and spacign between the regions are known
	--it's also possible to specify a prefix and a padding to format the textures name
	local atlas = TextureAtlas.fromTexture("numbers.png",32,32,0,0,"numbers_",2)
	local tileSet = TileSet(atlas)
	local tileMapData = {}
	tileMapDataLarge = {}
	--build a grid only with decimal numbers
	for i = 1, 64 do
		if (i-1) % 16 < 10 then
			tileMapData[#tileMapData + 1] = i
		end
	end
	
	for i = 1, 64 do
		tileMapDataLarge[i] = i
	end
	
	tileMap = TileMap(tileMapData, 8, 5, tileSet, PivotMode.CENTER)
	tm2 = tileMap:clone()
	tm2:setPosition(WIDTH/4, HEIGHT/4)
	stage:addChild(tileMap)
	stage:addChild(tm2)
	
	tileMap:setPosition(WIDTH/2, HEIGHT/2)
	tileMap:addEventListener(Event.TOUCH,onTouch)
	
	local scramble = Button(Texture.fromColor(120,40, 255,0,0), nil, "SCRAMBLE")
	scramble:getTextField():setAlignment(TextField.CENTER_JUSTIFY, TextField.CENTER_JUSTIFY)
	scramble:addEventListener(Event.TRIGGERED, onScrambleSwitch)
	scramble:setPosition(WIDTH - 150, 30)
	stage:addChild(scramble)

	local reset = Button(Texture.fromColor(120,40, 0,255,0), nil, "RESET")
	reset:getTextField():setAlignment(TextField.CENTER_JUSTIFY, TextField.CENTER_JUSTIFY)
	reset:addEventListener(Event.TRIGGERED, onResetSwitch)
	reset:setPosition(WIDTH - 150, 80)
	stage:addChild(reset)

end

function getRandomPos(w,h)
	local x = math.random(0,w)
	local x = x % w + 1
	local y = math.random(0,h)
	local y = y % h + 1
	return x,y
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
	if bEnableAnimation then
		local x1,y1 = getRandomPos(tileMap:getMapSize())
		local x2,y2 = getRandomPos(tileMap:getMapSize())
		local t1,f1 = tileMap:getTileId(x1,y1)
		local t2,f2 = tileMap:getTileId(x2,y2)
		--Switch tile id keeping current tile flags. This way the flipped status 
		--is preserved in the location where it was changed
		tileMap:setTile(x1,y1,t2,f1)
		--setTile can be called either providing id, flags or id+flags.
		--id+flags, flags raise an error
		tileMap:setTile(x2,y2,t1+f2)
		--tileMap:setRotation(tileMap:getRotation() + math.pi / 200)
	end
end

function onTouch(e)
	local touch = e.touch
	if touch.state == Touch.BEGAN then
		local x,y = tileMap:positionToGrid(touch.x, touch.y)
		tileMap:toggleTileFlags(x,y,TileMap.TILE_Y_FLIP)
	end
end

function onScrambleSwitch()
	bEnableAnimation = not bEnableAnimation
end

function onResetSwitch()
	tileMap:replaceMapData(tileMapDataLarge,8,8)
end

--called when no hittable object is hit by the current touch. By default each object added to the stage
--is hittable. a displayObjContainer by default forward the hit test to the children, unless is requested to handle
--the hit test directly. If a displayObjContainer is set as "not touchable" all his children will not be touchable.
--Therefore if the stage is set as not touchable every touch is redirected here
function touched(touch)
	if touch.state == Touch.BEGAN then
		tileMap:setRotation(tileMap:getRotation()+math.pi/4)
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()