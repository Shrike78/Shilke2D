-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

--By default (0,0) is topleft point and y is from top to bottom. Definint this allows to 
--set (0,0) as bottomleft point and having y from bottom to top.
--__USE_SIMULATION_COORDS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

local clipW = WIDTH/2
local clipH = HEIGHT/2

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
	
	local juggler = shilke.juggler 
	
	--show as overlay fps and memory allocation
	shilke:showStats(true,true)
		
	--Set a "moai.png" image as background at full screen
	local moaiImg = Image(Assets.getTexture("moai.png"))
	moaiImg:setScale(WIDTH / moaiImg:getWidth(), HEIGHT / moaiImg:getHeight())
	moaiImg:setPosition(WIDTH/2, HEIGHT/2)
	stage:addChild(moaiImg)
	
	--load the PlanetCute texture atlas and retrieves all the "Character*.png" textures
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute.xml")	
	local textures = atlas:getTextures("Character")
	
	--Create the displayContainer that will be clipped. 
	--It's centered with the middle point of clip area in center of screen adn rotated of 45°
	display = DisplayObjContainer()
	display:setPivot(clipW/2,clipH/2)
	display:setPosition(WIDTH/2,HEIGHT/2)
	display:setRotation(math.pi/4)
	
	--The contents container is the one with all the children imgs
	local contents = DisplayObjContainer()
	
	--add 100 random imgs to contents in random position
	for i = 1, 100 do 
		local idx = math.random(1,#textures)
		local img = Image(textures[idx])
		img:setPosition(math.random(WIDTH),math.random(HEIGHT))
		contents:addChild(img)
	end
	
	--center contents container in the middle of the screen / clip area
	contents:setPivot(contents:getWidth()/2,contents:getHeight()/2)
	contents:setPosition(clipW/2,clipH/2)
	display:addChild(contents)
	
	stage:addChild(display)
		
	--make contents rotate infinite times
	juggler:add(
		Tween.loop(
			DisplayObjTweener.moveRotation(contents,2*math.pi,math.random(10,15)),
			-1
		)
	)		
	
	--add on screen info
	local info = TextField(600, 50, "Click on screen to enable / disable the rotated rectangular clipArea.")
	info:setPosition(WIDTH/2,50)
	stage:addChild(info)
	
	--remove touchable status for the whole display list, so to let the touched event
	--to be called for every touch.
	stage:setTouchable(false)
	
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end


--on click enable / disable clipArea
function touched(touch)
	if touch.state == Touch.BEGAN then
		if 	display:hasClipArea() then
			display:destroyClipArea()
		else
			display:setClipArea(clipW,clipH)
		end
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()