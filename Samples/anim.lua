require("Shilke2D/include")

local WIDTH,HEIGHT = 1024,680
local FPS = 60

IO.setWorkingDir("Assets")


--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	
    local shilke = Shilke2D.current
	local stage = shilke.stage 
	
	--show as overaly fps and memory allocation
	shilke:showStats(true)
    
    --if not set, the default color is (0,0,0,255)
    stage:setBackground(10,10,10)
	
    --the juggler is the animator of all the animated objs, like
    --movieclips, tweens or other jugglers too.
    juggler = shilke.juggler
    
	local moaiImg = Image(Assets.getTexture("moai.png"))
	moaiImg:setPosition(WIDTH/2,HEIGHT/2)
	
	animJuggler = Juggler()
	
	animJuggler:add(
		Tween.parallel(
			moaiImg:seekRotation(-20*math.pi,5),
			moaiImg:seekColor(Color(255,0,0),2),
			Tween.sequence(
				moaiImg:movePosition(0,HEIGHT/2,2),
				moaiImg:movePosition(WIDTH/2,-HEIGHT,2)
			)
		)
	)
	
	stage:addChild(moaiImg)
	
	local moaiImg2 = moaiImg:clone()
	stage:addChild(moaiImg2)
	moaiImg2:setPosition(0,0)
	
	animJuggler:add(moaiImg2:seekTarget(moaiImg,5))
			
	juggler:add(
		Tween.loop(
			Tween.sequence(
				moaiImg2:seekScale(0.5,0.5,.2),
				moaiImg2:seekScale(1.5,1.5,.2)
			),
			-1
		)
	)
	
	juggler:add(animJuggler)
end

--update is called once per frame and allows to logically update status of objects
function update(elapsedTime)
end

--called when no object handle the current touch. if stage touch is disabled every touch is 
-- redirected here
function touched(touch)
	if touch.state == Touch.BEGAN then
		animJuggler:setPause(not animJuggler:isPaused())
	end
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(WIDTH,HEIGHT,FPS)
shilke2D:start()