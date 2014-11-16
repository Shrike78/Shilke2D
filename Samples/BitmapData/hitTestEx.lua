--[[
The sample shows the usage of BitmapData hitTest/hitTestEx.

To better show collisions the viewport is scaled by a factor 2 in both directions.

This functions allow to make a per pixel hit test of two MOAIImages 
(the extended version support also BitampRegions) given their relative
position and a minimum alpha level (per image) used to identify transparent 
pixels.

The functions work only with CPU BitmapRegions (MOAIImages), not with textures
beacuse textures cannot be queried for pixel informations.

If a per pixel collision detection is required then it's possible to keep a 
reference to the src MOAIImage and use it to make hit tests on Images/Textures.

NB: the functions work only with not scaled and not rotated images
--]]

-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 512,340
local SCALEX,SCALEY = 2,2

local FPS = 60

--different alphalevels lead to different collision detection results.
--this value is used either for pixelHitTest configuration, either for
--collision detection between images
local ALPHALEVEL = 0

--the working dir of the application
IO.setWorkingDir("Assets/PlanetCute")

--used for collision detection in update call
local boyImg, girlImg
	
function setup()
	
    local shilke = Shilke2D.current
	--show as overlay fps and memory allocation
	shilke:showStats(true,true)
	
	--the stage is the base displayObjContainer of the scene. Everything need to be connected to the
	--stage to be displayed.
	local stage = shilke.stage
	stage:setBackgroundColor(Color.GREY)
	
	local planetCuteBmp = BitmapData.fromFile("PlanetCute_optimized.png")
	local planetCuteTxt = Texture(planetCuteBmp)
		
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute_optimized.xml", planetCuteTxt)
	
	local boyTxt = atlas:getTexture("Character Boy.png") 
	boyImg = Image(boyTxt)	
	boyImg:setPosition(WIDTH/4,2*HEIGHT/4)
	boyImg:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(boyImg)

	--we retrieve the subtexture that was originally "Character Cat Girl".png and that is now a subregion of
	--the atlas texture
	local girlTxt = atlas:getTexture("Character Cat Girl.png") 
	--we create a static img setting the Pivot in top center position
	girlImg = Image(girlTxt)
	
	girlImg:setPosition(3*WIDTH/4,2*HEIGHT/4)
	girlImg:addEventListener(Event.TOUCH,onSpriteTouched)
	stage:addChild(girlImg)
	
	--setting framed to false would lead to higher memory usage (larger bitmaps) and
	--worst performances (more pixel to test)
	local framed = true
	--Create two smaller framed MOAIImages and release larger planetCuteBmp
	local boyBmp, boyFrame = BitmapData.cloneRegion(planetCuteBmp, boyTxt, framed)
	local girlBmp, girlFrame = BitmapData.cloneRegion(planetCuteBmp, girlTxt, framed)
	planetCuteBmp = nil

	--enable pixelPrecisionHitTests using the newly created bitmap regions
	boyImg:enablePixelHitTest(ALPHALEVEL, boyBmp, boyFrame)
	girlImg:enablePixelHitTest(ALPHALEVEL, girlBmp, girlFrame)

	local info = TextField(400,40,"Drag the characters and make them overlap.\nAlpha level is " .. ALPHALEVEL)
	info:setPosition(WIDTH/2,80)
	info:setHAlignment(TextField.CENTER_JUSTIFY)
	stage:addChild(info)

	collisionInfo = TextField(200,20, "")
	collisionInfo:setPosition(WIDTH/2,120)
	collisionInfo:setHAlignment(TextField.CENTER_JUSTIFY)
	stage:addChild(collisionInfo)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
	
	--the choosen textures have the same size. The images are both created with a default centered
	--pivot point, so the position can be used to calculate hitTest without any correction, even if
	--it refers to the center of the texture instead of the top left point
	--In a different situation the two position should be calculated displacing the imgs position
	--by their pivot position, or getting the bounds of images in stage target space and using the 
	--x,y coordinates of the resulting rect
	local bx,by = boyImg:getPosition()
	local gx,gy = girlImg:getPosition()
	local bCollision = false
	--get the required infos directly from images
	local _, boyBmp, boyRegion = boyImg:getPixelHitTestParams()
	local _, girlBmp, girlRegion = boyImg:getPixelHitTestParams()
	--the method accepts a position and an alpha treshold for the first texture and a second texture with
	--its position and alpha level.
	bCollision = BitmapData.hitTestEx(boyBmp, bx, by, ALPHALEVEL, girlBmp, gx, gy, ALPHALEVEL, boyFrame, girlFrame, 2)
	hitTestText = "hitTest"
	--update test result message
	collisionInfo:setText("hitTest = " .. tostring(bCollision))
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
		--If it exists and it's the same currently "dragged" by Shilke2D, then translate it
		if target and target == Shilke2D.current:getDraggedObj(touch) then
			--Global Translate allows to translate an obj based on stage coordinates.
			target:globalTranslate(touch.deltaX,touch.deltaY)
		end
	
	else
		--end of Touch event, reset to neutral color
		target:setColor(255,255,255)
	end
end


--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS,SCALEX,SCALEY)
shilke2D:start()