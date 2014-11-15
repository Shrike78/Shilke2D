--[[
Shilke2D has builtin support for drag and drop of objects.
It's based on the usage of different calls:

Shilke2D:startDrag(touch, object)
Shilke2D:stopDrag(touch, object)
Shilke2D:getDraggedObj(touch)

DisplayObj:globalTranslate(x,y)

The startDrag call binds a touch id to an specific object, so from this moment on, all events 
related to this touch id will be handled directly by registered object until the touch ending
(because ended or canceled). Without this call it's always the top most obj to be detected as 
hit.

the getDraggedObj returns the obj bound the the given touch id.

the stopDrag calls unbinds obj and touchid. It's usually not called because when the touch ends
the unbind is done automatically.

The globalTranslate method of DisplayObjs it's a translate done in another target space coordinate
system, by default the stage target space (that is also the touch coordinate system)

Using all this support together it's possible to easily achieve drag and drop features.
--]]

-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets/PlanetCute")


--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	
    local shilke = Shilke2D.current
	
	--the stage is the base displayObjContainer of the scene. Everything need to be connected to the
	--stage to be displayed.
	local stage = shilke.stage 
	
	--show as overlay fps and memory allocation
	--shilke:showStats(true)
	
	--show debug lines. by default only oriented bboxes
	stage:showDebugLines()
	
	--store bitmap for later usage
	local planetCuteBmp = BitmapData.fromFile("PlanetCute_optimized.png")
	
	--create a Texture from MOAIImage
	local planetCuteTxt = Texture(planetCuteBmp)
	
	--Create the atlas providing the already created Texture
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute_optimized.xml", planetCuteTxt)
	
	--Retrieve "Character Boy.png" subtexture
	local boyTxt = atlas:getTexture("Character Boy.png") 
	--Create an Image on boyTxt width default pivot (center position)
	local boyImg = Image(boyTxt)
	boyImg:setPosition(WIDTH/3,2*HEIGHT/3)	
	boyImg:setRotation(math.random()*2*math.pi)
	--Register an event listener for the touch event.
	boyImg:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(boyImg)

	--Retrieve "Character Cat Girl.png" subtexture
	local girlTxt = atlas:getTexture("Character Cat Girl.png") 
	--Create an Image on girlTxt width default pivot (center position)
	local girlImg = Image(girlTxt)
	girlImg:setPosition(2*WIDTH/3,2*HEIGHT/3)
	girlImg:setRotation(math.random()*2*math.pi)	
	--Enable pixel precise hitTest for girl Image, providing the planetCuteBmp as
	--MOAIImage source and the girlTxt as region
	girlImg:enablePixelPreciseHitTest(0, planetCuteBmp, girlTxt)
	girlImg:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(girlImg)
	
	local info = TextField(500, 250, "Drag and Drop example\n\nTry to draw around the two characters:\n" ..
		"\n-The boy hitTest is based on his oriented bounding box\n" ..
		"\n-The girl hitTest is based on pixel perfect detection, using alpha level set to 0", 
		nil, 20, 
		PivotMode.TOP_LEFT)
	
	info:setPosition(20,40)

	--info box cannot steal touch events from the 2 sprites
	info:setTouchable(false)
	
	stage:addChild(info)
end


--Handle touch events
function onSpriteTouched(e)
	
	local touch = e.touch
	local sender = e.sender
	local target = e.target
	
	if touch.state == Touch.BEGAN then
		--calling this function force the touch manager to address always this object for
		--touch/mouse events until Touch.ENDED state. Other objects therefore cannot 'steal' 
		--the focus from the dragged one. Without this call would be always the topmost 
		--object to take the focus
		Shilke2D.current:startDrag(touch,target)
		--force to red to show that is currently 'attached'
		target:setColor(255,0,0)
	
	elseif touch.state == Touch.MOVING then
		--check if the target exists: the sender notifies moving events starting inside its
		--touch area, even if the move ending point is outside it, and so the target it's different or nil.
		--If it exists and it's the same currently "dragged" by Shilke, then translate it
		if target and target == Shilke2D.current:getDraggedObj(touch) then
			--Global Translate allows to translate an obj based on stage coordinates.
			target:globalTranslate(touch.deltaX,touch.deltaY)
		end
	else
		--when the touch event ends, reset the dragged obj to neutral color
		target:setColor(255,255,255)
	end
end


--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()