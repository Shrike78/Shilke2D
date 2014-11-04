-- uncomment to debug touch and keyboard callbacks. works with Mobdebug
__DEBUG_CALLBACKS__ = true

--By default (0,0) is topleft point and y is from top to bottom. Definint this allows to 
--set (0,0) as bottomleft point and having y from bottom to top.
__USE_SIMULATION_COORDS__ = true

--include Shilke2D lib
require("Shilke2D/include")

local WIDTH,HEIGHT = 1024, 680
local FPS = 60

local NUMBER_OF_STARS = 100

--draw a star of a given size (external circle diameter)
function drawStar(s)
	for i = 1,6 do
		Graphics.setPenColor(240,245,255,i*10)
		Graphics.fillCircle(s/2, s/2, (s/2)/i)
	end
	Graphics.setPenColor(240,245,255,255)
	Graphics.fillCircle(s/2, s/2, 3)
end


function setup()

	local shilke = Shilke2D.current
	
	local stage = shilke.stage 
	local juggler = shilke.juggler
	
	--create a sky background using a quad, darker on top and brighter on bottom
	local fromColor = Color(39, 58, 103, 255)
	local toColor = Color(29, 27, 38, 255)
	local q = Quad(WIDTH,HEIGHT, PivotMode.BOTTOM_LEFT)
	q:setColors(fromColor, fromColor, toColor, toColor)
	stage:addChild(q)
	
	--create a 64x64 star texture, then rescaled to have a better smooth result
	local size = 64
	local ratio = size / 32
	local starTexture = Texture.fromDrawFunction(Callback(drawStar,size), size, size)
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
	stage:setTouchable(false)
end

shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()