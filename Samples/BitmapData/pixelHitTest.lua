--[[
It's possible to force Images to use a pixel precise hit test instead of 
the default bounding box based hit test.

Pixel precise hit must be done on a CPU bitmap because textures cannot be
queried for pixel informations. It's so possible to provide to an Image a 
MOAIImage and a region (if working with atlases) to be used in place of
the Image bounding for hitTest. The pixel precise hitTest retrieves the 
alpha value of the hit pixel and compares it with a given alpha level 
value.

In the following example the pixel precise hit test is enabled using an 
alpha level of 0, that means that pixels are considered transparent only
if their alpha is exactly 0.

The bitmap used as hitTest reference is the source bitmap used to build 
the texture atlas, and the region is the texture provided to the image
itself (because a texture is also a region over the source bitmap!)

To reduce memory allocation it would be possible to create a new bitmap
only for girlImage (using BitmapData.cloneRegion and keepFrame option 
active), releasing the atlas MOAIImage, and use the newly created, 
smaller framed MOAIImage for hitTest (check for commented code)
--]]

-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets/PlanetCute")

local boyImg, girlImg

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
	boyImg = Image(boyTxt)
	boyImg:setPosition(WIDTH/3,2*HEIGHT/3)
	--Register an event listener for the touch event.
	boyImg:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(boyImg)

	--Retrieve "Character Cat Girl.png" subtexture
	local girlTxt = atlas:getTexture("Character Cat Girl.png") 
	--Create an Image on girlTxt width default pivot (center position)
	girlImg = Image(girlTxt)
	girlImg:setPosition(2*WIDTH/3,2*HEIGHT/3)
	
	girlImg:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(girlImg)
	
	--Enable pixel precise hitTest for girl Image, providing the planetCuteBmp as
	--MOAIImage source and the girlTxt as region
	--alpha level used for hit test is 0
	girlImg:enablePixelHitTest(0, planetCuteBmp, girlTxt)
	
	--replace the previous instruction with the following to see how
	--different bitmap regions can be used for pixelHitTest
	--[[
	girlBmp, girlBmpFrame = BitmapData.cloneRegion(planetCuteBmp,girlTxt,true)
	girlImg:enablePixelHitTest(0, girlBmp, girlBmpFrame)
	--]]
	
	local info = TextField(500, 250, "Touching an Image change it's color to red." ..
		"\n\n-Boy hitTest is based on its oriented bounding box\n" ..
		"\n-Girl hitTest is based on pixel perfect check, with alpha level set to 0\n" .. 
		"\n-Touch this text to randomically change images rotation and scaling of the 2 images",
		nil, 20, 
		PivotMode.TOP_LEFT)
	info:setPosition(20,40)
	
	info:addEventListener(Event.TOUCH, onInfoTouched)
	stage:addChild(info)
end


function onInfoTouched(e)
	if e.touch.state == Touch.BEGAN then
		boyImg:setScale(math.random()*2,math.random()*2)
		boyImg:setRotation(math.random(-math.pi, math.pi))
		girlImg:setScale(math.random()*2,math.random()*2)
		girlImg:setRotation(math.random()*2*math.pi)
	end
end

--Handler for touch events
function onSpriteTouched(e)
	local touch = e.touch
	local sender = e.sender
	local target = e.target
	
	if touch.state == Touch.BEGAN then
		--force to red to show that is currently 'attached'
		target:setColor(255,0,0)
	
	--if touch state is ENDED or CANCELLED, reset color
	elseif touch.state ~= Touch.MOVING then
		sender:setColor(255,255,255)
	
	--if target sender differs, it means that the event was sent due to a moving event
	--from inside an object (sender) to outside the object (so the target is nil), so
	--reset the color of the sender
	elseif target ~= sender then
		sender:setColor(255,255,255)
	end
end


--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()