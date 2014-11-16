--[[
Example to load a texture atlas created with codeandweb's TexturePacker.

It's possible to test different type of packing and different formats changing
the 'TexturePacker.load***Format()' call before the setup() function

The atlas has been created in 2 different formats (MOAI with a lua descriptor and Sparrow with an
xml descriptor) and 4 different configuration per format:

- PlanetCute: simplest packing algs. Options available in free version of texture packer
- PlanetCute_rotated: texture can be packed using the MaxRect alg (that includes 90° rotation
of packed regions)
- PlanetCute_trimmed: support only trimming of empty bound area of packed textures
- PlanetCute_optimized: rotation and trimming together

It's possible to see how memory requirements changes between different configuration

--]]

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets")

--we load the atlas descriptor created with TexturePacker. 
--choose one of the following to see how different format and features are supported as well
local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute.xml")
--local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute_rotated.xml")
--local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute_trimmed.xml")
--local atlas = TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute_optimized.xml")

--local atlas = TexturePacker.loadMoaiFormat("PlanetCute/PlanetCute.lua")
--local atlas = TexturePacker.loadMoaiFormat("PlanetCute/PlanetCute_rotated.lua")
--local atlas = TexturePacker.loadMoaiFormat("PlanetCute/PlanetCute_trimmed.lua")
--local atlas = TexturePacker.loadMoaiFormat("PlanetCute/PlanetCute_optimized.lua")


--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	
    local shilke = Shilke2D.current
	
	--the stage is the base displayObjContainer of the scene. Everything need to be connected to the
	--stage to be displayed. The stage is a particular displayObjContainer because it can't be moved,scaled
	--or anyway transformed geometrically.
	local stage = shilke.stage 
	
	--if not set, the default color is (0,0,0)
	stage:setBackgroundColor(128,128,128)

	
	--retrieve the subtexture that was originally Character Boy.png and that is now a subregion of
	--the atlas texture
	local boyTexture = atlas:getTexture("Character Boy.png") 
	--we create a static img setting the Pivot in bottom center position
	local img = Image(boyTexture,PivotMode.BOTTOM_CENTER)
	--we placed the img at the bottom of the screen, in the middle
	img:setPosition(WIDTH/2,HEIGHT)
	stage:addChild(img)
	
	--force random position to be different every time
	math.randomseed(os.time())
	
	--retrieve all the textures that rapresents a character.
	--atlas:getTexture can be called with a string value that works as filter prefix on the name of the 
	--textures. If no filter is provided it returns all the textures oredered by name
	for _,texture in ipairs(atlas:getTextures("Character")) do
		local img = Image(texture)
		img:setPosition(math.random(0,WIDTH),math.random(0,HEIGHT))
		stage:addChild(img)
	end
end

shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()