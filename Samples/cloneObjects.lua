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


function createImage()
	return Image(Assets.getTexture("moai.png"))
end

function createQuad()
	return Quad(100,500)
end

function createMovieClip()
	local atlas = TextureAtlas.fromTexture("numbers.png",32,32,0,0,"numbers_",2)
	mc = MovieClip(atlas:getTextures(),12)
	Shilke2D.current.juggler:add(mc)
	mc:play(1,-1)
	return mc
end

function createTextField()
	local t = TextField(300,100,"Prova", nil, 60, PivotMode.CENTER)
	t:setHAlignement(TextField.CENTER_JUSTIFY)
	t:setColor(0,0,0)
	return t
end

function createObject()
	local dc = DisplayObjContainer()
	dc:addChild(createImage())
	dc:addChild(createQuad())
	dc:addChild(createMovieClip())
	dc:addChild(createTextField())
	return dc
end

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
	
    --the juggler is the animator of all the animated objs, like
    --movieclips, tweens or other jugglers too.
    juggler = shilke.juggler
    
	--create an Image, a static image object.
	--By default the pivot is set in the center of the image
	obj1 = createObject()
	obj1:setPosition(WIDTH/2,HEIGHT/2)

	
	--it's possible to create differente jugglers. That allows to have different animator for specific logics
	animJuggler = Juggler()
	
	--it's possible to create different animation and to play them sequentially, in parallel or in loop.
	--Each displayObj allows to create an animation that can be combined with other like in the following
	--example:
	
	--only one animation is added to the juggler, that is the group of 3 other animations.
	--the third one is again a combination, a sequence this time, of two different animation
	animJuggler:add(
		Tween.parallel(
			DisplayObjTweener.seekRotation(obj1,-20*math.pi,5),
			DisplayObjTweener.seekColor(obj1,Color(255,0,0),2),
			Tween.sequence(
				DisplayObjTweener.movePosition(obj1,0,HEIGHT/2,2),
				DisplayObjTweener.movePosition(obj1,WIDTH/2,-HEIGHT,2)
			)
		)
	)
	
	--each displayObj need to be connected to the stage to be rendered
	stage:addChild(obj1)
	
	local obj2 = obj1:clone()
	stage:addChild(obj2)
	obj2:setPosition(0,0)
	
	animJuggler:add(DisplayObjTweener.seekTargetPosition(obj2,obj1,5))
	animJuggler:add(DisplayObjTweener.seekAlpha(obj2,0,5))
			
	juggler:add(
		Tween.loop(
			Tween.sequence(
				DisplayObjTweener.seekScale(obj2,0.5,0.5,.2),
				DisplayObjTweener.seekScale(obj2,1.5,1.5,.2)
			),
			-1
		)
	)
	
	juggler:add(animJuggler)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end

--called when no object handle the current touch. if stage touch is disabled every touch is 
-- redirected here
function touched(touch)
	if touch.state == Touch.BEGAN then
		animJuggler:setPause(not animJuggler:isPaused())
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()