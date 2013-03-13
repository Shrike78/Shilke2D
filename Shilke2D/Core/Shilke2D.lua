-- Shilke2D Moai

Shilke2D = class()
--alias for old lib name
Starling = Shilke2D

function setup()
	--override setup method
end

function update(elapsedTime)
	--override update method
end

function onDirectDraw(index, xOff, yOff, xScale, yScale)
	--override onDirectDraw method
end

--by default in a desktop environment a keyboardEvent handler is defined so, if 
function onKeyboardEvent(key, down)
	--override function
	print(key,down)
end

function Shilke2D.isKeyPressed(key)
	return MOAIInputMgr.device.keyboard:keyIsDown(key)
end

--brand:
-- OSX
-- Windows
-- iOS
-- ??? Android ???
function Shilke2D.isMobile()
    local brand = MOAIEnvironment.osBrand
--    return brand == MOAIEnvironment.OS_BRAND_ANDROID or brand == MOAIEnvironment.OS_BRAND_IOS
    return brand == "iOS" or brand == "Android"
end

--------------------------------------------------------------------------------
-- Returns whether the desktop execution environment.
-- @return True in the case of desktop.
--------------------------------------------------------------------------------
function Shilke2D.isDesktop()
    return not Shilke2D.isMobile()
end

function Shilke2D:init(w,h,fps,scaleX,scaleY)

	self.w = w
	self.h = h
	self.fps = fps or 60
	self.scaleX = scaleX or 1
	self.scaleY = scaleY or 1
	MOAISim.openWindow("", self.w*self.scaleX, self.h*self.scaleY)
	
	--Set fixed performances at specific fps
	MOAISim.setStep(1/self.fps)
	MOAISim.clearLoopFlags ()
--	MOAISim.setLoopFlags ( MOAISim.SIM_LOOP_ALLOW_BOOST )
	MOAISim.setLoopFlags ( MOAISim.SIM_LOOP_LONG_DELAY )
	MOAISim.setBoostThreshold ( 0 )

if __USE_SIMULATION_COORDS__ then	
	self.renderViewport = MOAIViewport.new()
	self.renderViewport:setScale(self.w, self.h)
	self.renderViewport:setSize(self.w*self.scaleX, self.h*self.scaleY)

	setTouchSensorCorrection(self.scaleX, self.scaleY, self.h)
	self.renderViewport:setOffset(-1, -1)
else	
	self.renderViewport = MOAIViewport.new()
	self.renderViewport:setScale(self.w, -self.h)
	self.renderViewport:setSize(self.w*self.scaleX, self.h*self.scaleY)
	setTouchSensorCorrection(self.scaleX, self.scaleY)
	self.renderViewport:setOffset(-1, 1)
end

	self.stage = Stage(self.renderViewport)
	
	-- create a directDrawLayer where it's possible to just draw rect, circles, lines ecc.
    local directDrawDeck = MOAIScriptDeck.new ()
	if __DEBUG_CALLBACKS__ then
		directDrawDeck:setDrawCallback ( function(index, xOff, yOff, xScale, yScale)
					require('mobdebug').on()
					onDirectDraw(index, xOff, yOff, xScale, yScale)
				end)
	else
		directDrawDeck:setDrawCallback ( onDirectDraw )
	end
	self._directDrawLayer = MOAIProp.new()
	self._directDrawLayer:setDeck(directDrawDeck)
	
	self._renderTable = {self.stage._rt,self._directDrawLayer}
    MOAIRenderMgr.setRenderTable(self._renderTable)

	self.juggler = Juggler()

	Shilke2D.current = self
	
	--Stats management
	self.stats = DisplayObjContainer()
	
	self.info_stats = TextField(200,20, nil, 16, "")
	local bg_stats = Quad(200,20)
	bg_stats:setColor(Color(0,0,0))
	self.stats:addChild(bg_stats)
	self.stats:addChild(self.info_stats)
	
if __USE_SIMULATION_COORDS__ then	
	self.stats:setPosition(self.w/2,self.h - 20)
else
	self.stats:setPosition(self.w/2, 20)
end	
	self.info_stats._prop:setAlignment(MOAITextBox.CENTER_JUSTIFY)
	self._showStats = false
	MOAIUntzSystem.initialize()
end

function Shilke2D:start()
	self.log = Log()
    
	--first call setup method
	setup()

	--setup touch processor
    self.touchIds = {}
    self.ownedTouches = {}
	local __touched = touched
    touched = function(touch)
        local target = nil
        if self.ownedTouches[touch.id] then
            target = self.ownedTouches[touch.id]
        else
            target = self.stage:hitTest(touch.x,touch.y,nil,true)
        end
        local prevTarget = self.touchIds[touch.id]
        
        if prevTarget and prevTarget ~= target then
            prevTarget:dispatchEvent(TouchEvent(touch,target))
        end
        if target then
            target:dispatchEvent(TouchEvent(touch,target))
            if touch.state == Touch.ENDED then
                if self.touchIds[touch.id] then 
                    self.touchIds[touch.id] = nil
                end
                if self.ownedTouches[touch.id] then 
                    self.ownedTouches[touch.id] = nil
                end
            else
                self.touchIds[touch.id] = target
            end
        else
            self.touchIds[touch.id] = nil
            if __touched then
                __touched(touch)
            end
        end
    end
	
	if(Shilke2D.isDesktop()) then
		if __DEBUG_CALLBACKS__ then
			MOAIInputMgr.device.keyboard:setCallback ( function(key, down)
					require('mobdebug').on()
					onKeyboardEvent(key, down)
				end)
		else
			MOAIInputMgr.device.keyboard:setCallback ( onKeyboardEvent )
		end
	end
	
	---[[
	local mainJuggler = MOAICoroutine.new()
	mainJuggler:run(
		function()
			local elapsedTime = 0
			local prevElapsedTime = 0
			coroutine.yield()
			while (true) do
				coroutine.yield()

				local currElapsedTime = MOAISim.getElapsedTime()
				elapsedTime = currElapsedTime - prevElapsedTime
				prevElapsedTime = currElapsedTime
				self.juggler:advanceTime(elapsedTime)
			end
		end
	)		
	--]]
	--setup main loop
	local thread = MOAICoroutine.new()
	thread:run(
	function()
		--local prevElapsedTime = MOAISim.getDeviceTime()
		local elapsedTime = 0
		local prevElapsedTime = 0
		--force to skip a first 0 time frame
		coroutine.yield()
		while (true) do
			coroutine.yield()

			local currElapsedTime = MOAISim.getElapsedTime()
			elapsedTime = currElapsedTime - prevElapsedTime
			prevElapsedTime = currElapsedTime
			--self.juggler:advanceTime(elapsedTime)
			update(elapsedTime)
			if(self._showStats) then
			    local fps = MOAISim.getPerformance()
				local usage = MOAISim.getMemoryUsage()
				self.info_stats:setText(string.format("%f - %d",fps,usage.total))
			end
		end
	end
	)
end

function Shilke2D:getStage()
  return self.stage
end

function Shilke2D:getJuggler()
	return self.juggler
end

function Shilke2D:showStats(show)
	self._showStats = show
	if show and #self._renderTable == 2 then
		self._renderTable[3] = self.stats._renderTable
	elseif not show and #self._renderTable == 3 then
		self._renderTable[3] = nil
	end
end

--Any object can register itself as unique listener for a specific 
--touch (id) event. That's used to manage drag logic
function Shilke2D:startDrag(touch,obj)
    self.ownedTouches[touch.id] = obj
end

--An object can deregister itself as unique listener for a specific
--touch (id) event, but only if already registered
function Shilke2D:stopDrag(touch,obj)
    if self.ownedTouches[touch.id] ~= obj then
        error("displayObj is not set as owner for this touch")
    end
    self.ownedTouches[touch.id] = nil
end


