-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
__DEBUG_CALLBACKS__ = true

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
	
	local juggler = shilke.juggler 
	
	--show as overaly fps and memory allocation
	shilke:showStats(true)
	
	--show debug lines. by default only oriented bboxes
	stage:showDebugLines()
	
	--we load the atlas descriptor created with TexturePacker. The data was created with the
	--sparrow format so we make use of the TexturePacker helper function. Helpers also for corona and 
	--moai format exists.
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute.xml")
	
	--we retrieve the subtexture that was originally "Character Boy".png and that is now a subregion of
	--the atlas texture
	local boyTexture = atlas:getTexture("Character Boy.png") 
	--we create a static img setting the Pivot in bottom center position
	local boy = Image(boyTexture,PivotMode.BOTTOM_CENTER)
	boy:setPosition(WIDTH/3,2*HEIGHT/3)
	--we add an event listener for the 'touch' event.
	boy:addEventListener(Event.TOUCH,onSpriteTouched)
	boy:setRotation(-math.pi/3)
	stage:addChild(boy)

	--we retrieve the subtexture that was originally "Character Cat Girl".png and that is now a subregion of
	--the atlas texture
	local girlTexture = atlas:getTexture("Character Cat Girl.png") 
	--we create a static img setting the Pivot in top center position
	local girl = Image(girlTexture,PivotMode.TOP_CENTER)
	
	girl:setPosition(2*WIDTH/3,2*HEIGHT/3)
	girl:setRotation(math.pi/3)
	--we force the hitTest to be computed as pixel precise
	girl:setPixelPreciseHitTest(true)
	girl:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(girl)
	
	local info = TextField(500, 300, nil, 20, "Drag and Drop example\n\nTry to draw around the two characters:\n" ..
		"\n-The boy hitTest is based on his oriented bounding box\n" ..
		"\n-The girl hitTest is a pixel perfect check on the image, using alphaLevel set to 0", 
		PivotMode.TOP_LEFT)
	info:setPosition(20,40)
	--we don't want the info box stealing touch events from the 2 sprites
	info:setTouchable(false)
	
	stage:addChild(info)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end


function onSpriteTouched(e)
	local touch = e.touch
	local sender = e.sender
	local target = e.target
	
	if touch.state == Touch.BEGAN then
		--calling this function force the touch manager to address always this object for
		--touch/mouse events until Touch.ENDED state. That avoid other objects to steal the focus from the
		--dragged one
		Shilke2D.current:startDrag(touch,target)
		--force to red to show that is currently 'attached'
		target:setColor(255,0,0)
	elseif touch.state == Touch.MOVING then
		--check if the target exists: the sender notifies moving events the start inside it even if the 
		--move ending point is outside it, and so the target it's different or nil.
		--If it exists and it's the same currently "dragged" by Shilke, then translate it
		if target and target ==	Shilke2D.current:getDraggedObj(touch) then
			--Global Translate allows to translate an obj based on stage coordinates.
			target:globalTranslate(touch.deltaX,touch.deltaY)
		end
	else
		--reset to neutral color
		target:setColor(255,255,255)
	end
end

--called when no object handle the current touch. if stage touch is disabled every touch is 
--redirected here
function touched(touch)
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()