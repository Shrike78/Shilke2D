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
	
    --the juggler is the animator of all the animated objs, like
    --movieclips, tweens or other jugglers too.
    juggler = shilke.juggler
    
	--it's possible to load an image and automatically create sub regions if the regions
	--have all the same size and the margin and spacign between the regions are known
	--it's also possible to specify a prefix and a padding to format the textures name
	local atlas = TextureAtlas.fromTexture("numbers.png",32,32,0,0,"numbers_",2)
	
	--MovieClip inherits from Image and is the most simple way to put an animated obj, with a fixed frametime,
	--into the screen. It's initialized with the sequence of textures that will compose the animation and with
	--the animation fps value. Must be added to a juggler to be player and can be played starting from
	--a frame by choice and for an option number of times. negative values (like in the example) means 
	--"infinite loop"	
	mc = MovieClip(atlas:getTextures(),12)
	mc:setPosition(WIDTH/2,HEIGHT/2)
	stage:addChild(mc)
	juggler:add(mc)
	mc:play(1,-1)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end

--called when no hittable object is hit by the current touch. By default each object added to the stage
--is hittable. a displayObjContainer by default forward the hit test to the children, unless is requested to handle
--the hit test directly. If a displayObjContainer is set as "not touchable" all his children will not be touchable.
--Therefore if the stage is set as not touchable every touch is redirected here
function touched(touch)
	if touch.state == Touch.BEGAN then
		--the order of frames is inverted each time the screen is 'touched'
		mc:stop()
		mc:invertFrames()
		mc:play(1,-1)
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()