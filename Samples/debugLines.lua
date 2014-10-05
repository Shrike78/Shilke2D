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
	
	local juggler = shilke.juggler
	
	--show as overlay fps and memory allocation
	shilke:showStats(true)
    
	--show debug lines around displayObjs. show both aabbox and oriented bbox lines
	stage:showDebugLines(true,true)

	--we load the atlas descriptor created with TexturePacker. The data was created with the
	--sparrow format so we make use of the TexturePacker helper function. Helpers also for corona and 
	--moai format exists.
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute.xml")
	
	--we retrieve the subtexture that was originally Character Boy.png and that is now a subregion of
	--the atlas texture
	local boyTexture = atlas:getTexture("Character Boy.png") 
	--we create a static img setting the Pivot in bottom center position
	local img1 = Image(boyTexture,PivotMode.BOTTOM_CENTER)
	--we placed the img at the bottom of the screen, in the middle
	img1:setPosition(2*WIDTH/3,HEIGHT/2)
	--rotate of pi/3 on pivot (so bottom center position)
	img1:setRotation(math.pi/3)
	stage:addChild(img1)
	
	--infinite loop of opposite scaling of x,y direction
	juggler:add(Tween.loop(
			Tween.sequence(
				DisplayObjTweener.seekScale(img1,1.5,.5,2),
				DisplayObjTweener.seekScale(img1,0.5,1.5,2)
			),
			-1
		)
	)
	
	--we retrieve the subtexture that was originally Character Boy.png and that is now a subregion of
	--the atlas texture
	local girlTexture = atlas:getTexture("Character Cat Girl.png") 
	--we create a static img setting the Pivot in center position
	local img2 = Image(girlTexture,PivotMode.BOTTOM_LEFT)
	--we placed the img at the bottom of the screen, in the middle
	img2:setPosition(WIDTH/3,HEIGHT/2)
	stage:addChild(img2)
	
	--infinite loop of rotation around pivot (bottom left point)
	juggler:add(
		Tween.loop(
			DisplayObjTweener.seekRotation(img2,2*math.pi,5),
			-1
		)
	)
	
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end

--called when no object handle the current touch. if stage touch is disabled every touch is 
--redirected here
function touched(touch)
	if touch.state == Touch.BEGAN then
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()