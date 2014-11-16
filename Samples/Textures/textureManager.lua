
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
	
	--PlanetCute atlas is mounted at workingDir/"PlanetCute" (=> "/Assets/PlanetCute").
	--All the resources of PlanetCute atlas will then be available as normal resources under the
	--virtually mounted PlanetCute directory.
	TextureManager.mountAtlas("PlanetCute", TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute_optimized.xml"))
	
	--numbers atlas is mounted as workingDir/"numbers" (=> "/Assets/numbers").
	--All the resources of numbers atlas will then be available as normal resources under the
	--virtually mounted numbers directory.
    TextureManager.mountAtlas("Numbers", TextureAtlas.fromTexture("numbers.png",32,32,0,0,"Number_",2))
	
	--It's now possible to get "Character Boy.png" texture as it was a real texture
	local boyTexture = TextureManager.getTexture("PlanetCute/Character Boy.png") 
	local boyImg = Image(boyTexture)
	boyImg:setPosition(WIDTH/4,HEIGHT/2)
	
	--It's now possible to get "numbers_01.png" texture as it was a real texture	
	local numberTexture = TextureManager.getTexture("Numbers/Number_01.png") 
	local numberImg = Image(numberTexture)
	numberImg:setPosition(2*WIDTH/4,HEIGHT/2)
	
	--moai.png is a real texture and can be retrieved by TextureManager.
	--getTexture by default automatically registers unregistered textures.
	--It's also possible to register a texture with a custom name and path
	--using TextureManager.addTexture()
	local moaiTexture = TextureManager.getTexture("Moai.png") 
	local moaiImg = Image(moaiTexture)
	moaiImg:setPosition(3*WIDTH/4,HEIGHT/2)
	
	for _,name in ipairs(TextureManager.getRegisteredNames()) do
		print(name)
	end
	stage:addChild(moaiImg)
	stage:addChild(boyImg)
	stage:addChild(numberImg)

end


shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()