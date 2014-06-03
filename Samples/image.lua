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
    stage:setBackground(10,10,10)
    
	--create an Image, a static image object.
	--By default the pivot is set in the center of the image
	local moaiImg = Image(Assets.getTexture("moai.png"))
	
	--if not set, default position of a displyaObj is 0,0
	--we put the image in the centre of the screen
	moaiImg:setPosition(WIDTH/2,HEIGHT/2)
	
	--each displayObj need to be connected to the stage to be rendered
	stage:addChild(moaiImg)
	
	--The Assets.getTexture call by default caches the texture that is retrieved so making several
	--Assets.getTexture call over the same texture is the same to retrieve it once and use it 
	--several times
	--This time we created an img with TOP_LEFT pivot
	--by default image position is 0,0, so top left coord of the screen
	--so we are placing the top left point of the img into the top left point of the screen
	local moaiImg2 = Image(Assets.getTexture("moai.png"),PivotMode.TOP_LEFT)
	stage:addChild(moaiImg2)
	
	--This time we created an img with BOTTOM_RIGHT pivot
	local moaiImg3 = Image(Assets.getTexture("moai.png"),PivotMode.BOTTOM_RIGHT)
	--we are placing the bottom right point of the img into the bottom right point of the screen
	moaiImg3:setPosition(WIDTH,HEIGHT)
	stage:addChild(moaiImg3)
		
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end

--called when no object handle the current touch. if stage touch is disabled every touch is 
-- redirected here
function touched(touch)
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()