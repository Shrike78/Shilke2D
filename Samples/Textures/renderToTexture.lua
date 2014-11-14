--[[
Example of procedural scene creation: a starfield is obtained rendering a drawed star 
object on a texture then used with several images of different size / alpha. 
The background is obtained with a gradient colored quad.
--]]

-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
--__DEBUG_CALLBACKS__ = true

__USE_SIMULATION_COORDS__ = true

require("Shilke2D/include")

local WIDTH,HEIGHT = 1024, 680
local FPS = 60


--number of star to show on screen
local NUMBER_OF_STARS = 100
--draw a star of a given size (STAR_RADIUS variable)
local STAR_RADIUS = 32

--function used for render to texture of a single star
function drawStar()
	for i = 1,6 do
		Graphics.setPenColor(240,245,255,i*10)
		Graphics.fillCircle(STAR_RADIUS, STAR_RADIUS, STAR_RADIUS/i)
	end
	Graphics.setPenColor(240,245,255,255)
	Graphics.fillCircle(STAR_RADIUS, STAR_RADIUS, 3)
end


--Setup is called once at the beginning of the application, just after Shilke2D initialization.
function setup()

	local shilke = Shilke2D.current
	--Stage is the base displayObjContainer of the scene. Everything must be connected to the
	--stage to be displayed. The stage is a particular displayObjContainer because it can't be 
	--geometrically transformed.
	local stage = shilke.stage 
	
	--create a sky background using a quad, darker on top and brighter on bottom
	local fromColor = Color(39, 58, 103, 255)
	local toColor = Color(29, 27, 38, 255)
	local q = Quad(WIDTH,HEIGHT, PivotMode.BOTTOM_LEFT)
	q:setColors(fromColor, fromColor, toColor, toColor)
	stage:addChild(q)
	
	--create a 64x64 star texture, then rescaled to have a better smooth result
	local size = STAR_RADIUS*2
	local ratio = size / 32
	local starTexture = Texture.fromDrawFunction(drawStar, size, size)
	starTexture:setFilter(Texture.GL_LINEAR)
	
	--create everytime a different starfield
	math.randomseed(os.time())
	
	for i = 1, NUMBER_OF_STARS do
		--set random position / scale / alpha. 
		local x = math.random(WIDTH)
		local y = math.random(HEIGHT)
		local s = math.random(size/2, size)   
		--alpha is greater near the bottom of the scene because stars become less visible
		local a = math.random(60,255) * math.max(y, HEIGHT/3)/HEIGHT 
		local star = Image(starTexture)
		star:setPosition(x,y)
		star:setScale(s/(size*ratio),s/(size*ratio))
		star:setAlpha(a)
		stage:addChild(star)		
	end
end

shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()