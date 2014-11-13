

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

--the working dir of the application
IO.setWorkingDir("Assets")


--Setup is called once at the beginning of the application, just after Shilke2D initialization.
function setup()
	
    local shilke = Shilke2D.current
	
	--Stage is the base displayObjContainer of the scene. Everything need to be connected to the
	--stage to be displayed. The stage is a particular displayObjContainer because it can't be 
	--geometrically transformed.
	local stage = shilke.stage 
	
	--if not set, the default color is (0,0,0)
	stage:setBackgroundColor(128,128,128)
	
	--PlanetCute atlas is mounted at workingDir/"PlanetCute", that means "/Assets/PlanetCute"
	--All the resources of PlanetCute atlas will then be available as normal resources under the
	--PlanetCute directory. If empty string is provided instead of "PlanetCute" all the resources
	--became available in current working dir.
	TextureManager.mountAtlas("PlanetCute", TexturePacker.loadSparrowFormat("PlanetCute/PlanetCute.xml"))
    	
	--We can now retrieve Character Boy.png without caring if it's a real texture or a
	--atlas resource
	local boyTexture = TextureManager.getTexture("PlanetCute/Character Boy.png") 
	local boyImg = Image(boyTexture)
	boyImg:setPosition(WIDTH/3,HEIGHT/2)
	
	--moai.png is a real texture and can be retrieved by TextureManager.
	--TextureManager redirects to Assets the load of the texure
	local moaiTexture = TextureManager.getTexture("moai.png") 
	local moaiImg = Image(moaiTexture)
	moaiImg:setPosition(2*WIDTH/3,HEIGHT/2)
	
	stage:addChild(boyImg)
	stage:addChild(moaiImg)
end


shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()