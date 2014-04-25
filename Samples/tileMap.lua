-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

--By default (0,0) is topleft point and y is from top to bottom. Definint this allows to 
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
	for i = 1, 64 do
		tileMapData[i] = i
	end
	tileMap = TileMap(tileMapData, 8, 8, tileSet, PivotMode.CENTER)
	stage:addChild(tileMap)
	tileMap:setPosition(WIDTH/2, HEIGHT/2)
	tileMap:addEventListener(Event.TOUCH,onTouch)
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
	local x1,y1 = getRandomPos(8,8)
	local x2,y2 = getRandomPos(8,8)
	local t1,f1 = tileMap:getTileId(x1,y1)
	local t2,f2 = tileMap:getTileId(x2,y2)
	tileMap:setTile(x1,y1,t2,f1)
	tileMap:setTile(x2,y2,t1,f2)
	--tileMap:setRotation(tileMap:getRotation() + math.pi / 200)
end

function onTouch(e)
	local touch = e.touch
	if touch.state == Touch.BEGAN then
		local x,y = tileMap:positionToGrid(touch.x, touch.y)
		tileMap:toggleTileFlags(x,y,TileMap.TILE_Y_FLIP)
	end
end

--called when no hittable object is hit by the current touch. By default each object added to the stage
--is hittable. a displayObjContainer by default forward the hit test to the children, unless is requested to handle
--the hit test directly. If a displayObjContainer is set as "not touchable" all his children will not be touchable.
--Therefore if the stage is set as not touchable every touch is redirected here
function touched(touch)
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()