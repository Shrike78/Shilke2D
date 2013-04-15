-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

--By default (0,0) is topleft point and y is from top to bottom. Definint this allows to 
--set (0,0) as bottomleft point and having y from bottom to top.
--__USE_SIMULATION_COORDS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

local NUM_IMGS = 50
local SUBDISPLAY_WIDTH = 600
local SUBDISPLAY_HEIGHT = 300

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
		
	--load the PlanetCute texture atlas
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute.xml")
	
	--retrieves all the textures contained into the atlas
	local textures = atlas:getTextures()
	--takes a reference of all the containers so to be able to set them flatten/unflatten in the touched()
	--callback
	containerList = {}
	
	--takes count of the number of imgs that will be rendered
	local numImgs = 0
	
	--for each type of texture it creates a container with NUM_IMGS random positioned textures
	--and make it rotated infinite time at different randomic speed
	for _,texture in ipairs(textures) do
		local display = DisplayObjContainer()
		containerList[#containerList+1] = display
		--create 300 sprites in random position and add them to display
		for i=1,NUM_IMGS do
			local img = Image(texture)
			numImgs = numImgs +1
			--[[
			We put each sprite in random position.
			We avoid to put imgs with a negative x or y point in display coord system. 
			That's because the flatten logic create a clirect area with zero coord in the
			point (0,0) of the displayObjContainer and clips what is behind
			--]]
			img:setPosition(math.random(img:getWidth()/2,SUBDISPLAY_WIDTH-img:getWidth()/2),
							math.random(img:getHeight()/2,SUBDISPLAY_HEIGHT-img:getHeight()/2))
			display:addChild(img)
		end
		--flatten display to be a single image object
		stage:addChild(display)
				
		--Set display position in a random point inside the screen and make it rotates infinite times
		--around its center.
		display:setPivot(display:getWidth()/2,display:getHeight()/2)
		display:setPosition(math.random(WIDTH),math.random(HEIGHT))
		
		juggler:add(
			Tween.loop(
				DisplayObjTweener.moveRotation(display,2*math.pi,math.random(10,15)),
				-1
			)
		)		
	end
	
	--add on screen info
	local info = TextField(800, 300, "Show how flattened displayObjContainers are render optimized. " .. 
		numImgs .. " images are rendered." .. 
		"Click on screen to switch between flattened / unflattened displayObjContainer.")
	info:setPosition(WIDTH/2,HEIGHT/2)
	stage:addChild(info)
	
	--make info2 global because we want to update its text in touched() callback
	info2 = TextField(300, 50, "Flattened status = " .. tostring(containerList[1]:isFlattened()))		
	info2:setPosition(WIDTH/2,HEIGHT - 50)
	stage:addChild(info2)
	
	--remove touchable status for the whole display list, so to let the touched event
	--to be called for every touch.
	stage:setTouchable(false)
	
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end


--on click flatten status of display is switched
function touched(touch)
	if touch.state == Touch.BEGAN then
		for _,c in ipairs(containerList) do
			if c:isFlattened() then 
				c:unflatten() 
			else 
				c:flatten()
			end			
		end
		info2:setText("Flattened status = " .. tostring(containerList[1]:isFlattened()))		
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()