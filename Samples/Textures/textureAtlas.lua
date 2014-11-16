--Shows how to create a texture atlas starting from a tiled image.

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets")


--Setup is called once at the beginning of the application, just after Shilke2D initialization.
function setup()
	
    local shilke = Shilke2D.current
	
	--Stage is the base DisplayObjContainer of the scene. Everything need to be connected to the
	--stage to be displayed.
	local stage = shilke.stage 
	
	stage:setBackgroundColor(128,128,128)
	
	--Create a texture atlas starting from numbers.png. Each subtextures is
	--a tile of 32x32 pixel, with no spacing and no margin between tiles.
	--The name of the regions is generated automatically using provided params,
	--and will be a sequence of "numbers_" + progessive id starting from 1,
	--with a padding of 2: numbers_01, numbers_02, ecc.
	local atlas = TextureAtlas.fromTexture("numbers.png",32,32,0,0,"numbers_",2)
	--print all the named regions created
	for _,name in ipairs(atlas:getSortedNames()) do
		print(name)
	end
	--returns all the textures named alphabetically
	local textures = atlas:getTextures()
	
	--creates images starting from textures and places on screen
	--numbers is a squared texture so math.sqrt is the edge
	local size = math.sqrt(#textures)
	--distance between images
	local dw = 64
	local dh = 64
	for x=0, size-1 do
		for y=0, size-1 do
			local img = Image(textures[1+x+size*y], PivotMode.TOP_LEFT)
			img:setPosition(x*dw,y*dh)
			stage:addChild(img)
		end
	end
	
	--shows also original textures as single image
	local numbers = Image(atlas:getBaseTexture(), PivotMode.TOP_RIGHT)
	numbers:setPosition(WIDTH, 0)
	stage:addChild(numbers)
end


shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()