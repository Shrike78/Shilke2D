-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
__DEBUG_CALLBACKS__ = true

--By default (0,0) is topleft point and y is from top to bottom. Defining this allows to 
--set (0,0) as bottomleft point and having y from bottom to top.
--__USE_SIMULATION_COORDS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets")

-- declared here because visible also in the update() function
local boy,girl,collisionInfo
local planetCuteImg

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
	
	planetCuteImg = BitmapData.fromFile("PlanetCute/PlanetCute.png")
	--we load the atlas descriptor created with TexturePacker. The data was created with the
	--sparrow format so we make use of the TexturePacker helper function. Helpers also for corona and 
	--moai format exists.
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute.xml", Texture(planetCuteImg))
	
	--we retrieve the subtexture that was originally "Character Boy".png and that is now a subregion of
	--the atlas texture
	local boyTexture = atlas:getTexture("Character Boy.png") 
	--we create a static img setting the Pivot in bottom center position
	boy = Image(boyTexture,PivotMode.TOP_LEFT)
	boy:setPosition(WIDTH/4,2*HEIGHT/4)
	--we add an event listener for the 'touch' event.
	boy:addEventListener(Event.TOUCH,onSpriteTouched)
	--we set a pixel precision hit test for the image with an alpha treshold of 128 to identify transparent pixels
	boy:enablePixelPreciseHitTest(128, planetCuteImg, boyTexture)
	stage:addChild(boy)

	--we retrieve the subtexture that was originally "Character Cat Girl".png and that is now a subregion of
	--the atlas texture
	local girlTexture = atlas:getTexture("Character Cat Girl.png") 
	--we create a static img setting the Pivot in top center position
	girl = Image(girlTexture,PivotMode.TOP_LEFT)
	
	girl:setPosition(3*WIDTH/4,2*HEIGHT/4)
	girl:addEventListener(Event.TOUCH,onSpriteTouched)
	--we set a pixel precision hit test for the image with an alpha treshold of 128 to identify transparent pixels
	girl:enablePixelPreciseHitTest(128, planetCuteImg, girlTexture)
	stage:addChild(girl)
	
	local info = TextField(WIDTH-40, 300,
		"Drag and Drop with collision detection sample:\n" ..
		"\n-Textures in Shilke2D are equivalent to BitmapData in flash and have a similar "..
		"\n hitTest() method that make a per pixel comparison given 2 texures, space positions "..
		"\n and alpha thresholds to identify transparent pixels"..
		"\n\n-If 2 images are not scaled and not rotated it's possibile to use the texture:hitTest()"..		
		"\n method to compare the images",	
		nil, 20, 
		PivotMode.TOP_LEFT)
	info:setPosition(20,40)
	info:setTouchable(false)
	stage:addChild(info)

	local info2 = TextField(400,20,"Drag the characters and make them overlap")
	info2:setPosition(WIDTH/2,HEIGHT-120)
	stage:addChild(info2)

	collisionInfo = TextField(150,20, "")
	collisionInfo:setPosition(WIDTH/2,HEIGHT-100)
	stage:addChild(collisionInfo)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
	--the method accepts a position and an alpha treshold for the first texture and a second texture with
	--its position and alpha level.
	--in this sample the position is retrieved by images just because both the images have pivot set as
	--top_left. In a different situation the two position should be calculated displacing the imgs position
	--by their pivot position
	local bx,by = boy:getPosition()
	local gx,gy = girl:getPosition()
	
	if BitmapData.hitTestEx(planetCuteImg, bx, by, 128, planetCuteImg, gx, gy, 128, boy:getTexture(), girl:getTexture()) then
		collisionInfo:setText("Collision = true")
	else
		collisionInfo:setText("Collision = false")
	end
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
		target:setColor(255,128,128)
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