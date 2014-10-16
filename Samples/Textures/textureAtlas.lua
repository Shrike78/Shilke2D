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
	
	--if not set, the default color is (0,0,0)
	stage:setBackgroundColor(128,128,128)

	--we load the atlas descriptor created with TexturePacker. 
	--choose one of the following to see how different format and features are supported as well
	local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute.xml")
	--local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute_rotated.xml")
	--local atlas = TexturePacker.loadMoaiFormat("PlanetCute/PlanetCute.lua")
	--local atlas = TexturePacker.loadMoaiFormat("PlanetCute/PlanetCute_rotated.lua")
	
	--we retrieve the subtexture that was originally Character Boy.png and that is now a subregion of
	--the atlas texture
	local boyTexture = atlas:getTexture("Character Boy.png") 
	--we create a static img setting the Pivot in bottom center position
	local img = Image(boyTexture,PivotMode.BOTTOM_CENTER)
	--we placed the img at the bottom of the screen, in the middle
	img:setPosition(WIDTH/2,HEIGHT)
	stage:addChild(img)
	
	--now we retrieve all the textures that rapresents a character.
	--atlas:getTexture can be called with a string value that works as filter prefix on the name of the 
	--textures. If no filter is provided it returns all the textures oredered by name
	for _,texture in ipairs(atlas:getTextures("Character")) do
		local img = Image(texture)
		--we set random position
		img:setPosition(math.random(0,WIDTH),math.random(0,HEIGHT/2))
		stage:addChild(img)
	end
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