-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

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
	
	--PlanetCute atlas is mounted at workingDir/"PlanetCute", that means "/Assets/PlanetCute"
	--All the resources of PlanetCute atlas will then be available as normal resources under the
	--PlanetCute directory. If empty string is provided instead of "PlanetCute" all the resources
	--became available in current working dir.
	TextureManager.mountAtlas("PlanetCute",TexturePacker.loadSparrowFormat("PlanetCute.xml"))
    	
	--We can now retrieve Character Boy.png without caring if it's a real texture or a
	--atlas resource
	local boyTexture = TextureManager.getTexture("PlanetCute/Character Boy.png") 
	--we create a static img setting the Pivot in bottom center position
	local boyImg = Image(boyTexture)
	boyImg:setPosition(WIDTH/3,HEIGHT/2)
	
	--moai.png is a real texture and can be retrieved by TextureManager.
	--TextureManager redirects to Assets the load of the texure
	local moaiTexture = TextureManager.getTexture("moai.png") 
	local moaiImg = Image(moaiTexture)
	moaiImg:setPosition(2*WIDTH/3,HEIGHT/2)
	
	stage:addChild(boyImg)
	stage:addChild(moaiImg)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end

--called when no object handle the current touch. if stage touch is disabled every touch is 
--redirected here
function touched(touch)
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()