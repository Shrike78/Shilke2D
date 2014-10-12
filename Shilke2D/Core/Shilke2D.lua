 --[[---
Shilke2D Moai version
Shilke2D is the main class of Shilke2D lib. It initializes MOAI environment: 
rendering, audioaand input system.
It initializes also main juggler, log system and Stage
--]]
Shilke2D = class()


---Alias for old lib name. Can be used in place of Shilke2D
Starling = Shilke2D

---internal use only. Used to convert DisplayObjContainer to textures
Shilke2D.__frameBufferTables = {}


---Called at the beginning of the application.
-- Can be considered as the entry point of the application, where to initialize everything
function setup()
	--override setup method
end

---Called each frame.
-- Is where logic of the application is updated each frame, just before rendering.
-- @param elapsedTime the time elapsed since last call of the function
function update(elapsedTime)
	--override update method
end

---Called after draw to allow overlay drawing with graphics vetorial functions.
function onDirectDraw()
	--override onDirectDraw method
end

--[[---
Handle keyboard events.
Called only on desktop hosts.
@param key the key that has been pressed or released
@param down key status
--]]
function onKeyboardEvent(key, down)
	--override function
end

--- Check the key status of a given key code
function Shilke2D.isKeyPressed(key)
	return MOAIInputMgr.device.keyboard:keyIsDown(key)
end

--[[---
Check the platform on which the application is running and return true if the platform is mobile

It cheks the osBrand string with some predefined string, that are:

OSX, Windows, iOS, Android
@return true if brand è iOS o Android
--]]
function Shilke2D.isMobile()
    local brand = MOAIEnvironment.osBrand

--    return brand == MOAIEnvironment.OS_BRAND_ANDROID or brand == MOAIEnvironment.OS_BRAND_IOS
    return brand == "iOS" or brand == "Android"
end

--[[---
-- Check if the application is running on desktop.
-- @return True in the case of desktop.
--]]
function Shilke2D.isDesktop()
    return not Shilke2D.isMobile()
end

--[[---
Shilke2D must be created at the beginning of the application.
The initialization of Shilke2D setup MOAI rendering system and untz audio system
Stage, Juggler and log system are initialized here too.
@param w logical width of the viewport
@param h logical height of the viewport
@param fps desired frame rate
@param scaleX on screen viewport scale on x axe
@param scaleY on screen viewport scale on y axe
@param soundSampleRate audio system sample rate
@param soundFrames audio system number of frames
--]]
function Shilke2D:init(w,h,fps, scaleX,scaleY, soundSampleRate, soundFrames)

	self.log = Log()

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
		directDrawDeck:setDrawCallback ( function()
					require('mobdebug').on()
					onDirectDraw()
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
	self.stats = Stats()
	self.stats:setHittable(true)
	self._showStats = false
	if __USE_SIMULATION_COORDS__ then
		self.stats:setPosition(self.w/2, self.h - 20)
	else
		self.stats:setPosition(self.w/2, 20)
	end
	
	if MOAIUntzSystem then
		MOAIUntzSystem.initialize(soundSampleRate, soundFrames)
	else
		print("warning: UNTZ system is disabled")
	end
end


--[[---
Start Shilke2D application execution.
At first it calls the setup() function.
Then touch / mouse system is initialized.
If the application is running on a desktop environment also the keyboard system is initialized.
Juggler and update coroutines are finally created and executed, and the application can run.
--]]
function Shilke2D:start()
    
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
			--manually set position because the stats object is not attached to 'stage' so 
			-- hitTest logic cannot work properly
			if self.stats and self._statsForceGarbage then
				local x,y = touch.x, touch.y
				
				--because stats is not attached to stage, must adjust position touch manually 
				--in order to make a local coords hittest
				x = x - self.stats:getPositionX()
				y = y - self.stats:getPositionY()
				
				if self.stats:hitTest(x,y,nil,true) then
					--if stats is hit collectgarbare and return
					--newer MOAI version have a forceGarbageCollection call
					if MOAISim.forceGarbageCollection then
						MOAISim.forceGarbageCollection()
					else
						collectgarbage()
					end
					return
				else
					target = self.stage:hitTest(touch.x,touch.y,nil,true)					
				end
			else
				target = self.stage:hitTest(touch.x,touch.y,nil,true)
			end
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
	
	if __JUGGLER_ON_SEPARATE_COROUTINE__ then
		local mainJuggler = MOAICoroutine.new()
		mainJuggler:run(
			function()
				local elapsedTime, prevElapsedTime, currElapsedTime = 0, 0, 0
				coroutine.yield()
				while (true) do
					coroutine.yield()
					currElapsedTime = MOAISim.getElapsedTime()
					elapsedTime = currElapsedTime - prevElapsedTime
					prevElapsedTime = currElapsedTime
					self.juggler:advanceTime(elapsedTime)
				end
			end
		)		
	end
	
	--setup main loop
	local thread = MOAICoroutine.new()
	thread:run(
	function()
		local elapsedTime, prevElapsedTime, currElapsedTime = 0, 0, 0
		--force to skip a first 0 time frame
		coroutine.yield()
		while (true) do
			coroutine.yield()
			currElapsedTime = MOAISim.getElapsedTime()
			elapsedTime = currElapsedTime - prevElapsedTime
			prevElapsedTime = currElapsedTime
			--used to have the juggler update into the same coroutine
			if not __JUGGLER_ON_SEPARATE_COROUTINE__ then
				self.juggler:advanceTime(elapsedTime)
			end
			update(elapsedTime)
			if(self._showStats) then
				self.stats:update()
			end
		end
	end
	)
end

---Return the stage
function Shilke2D:getStage()
  return self.stage
end

---Return the main juggler
-- other juggler can be created and added to the main juggler for automatic updates, 
-- or can be updated manually 
function Shilke2D:getJuggler()
	return self.juggler
end

---Debug function that allows to show on screen average fps and memory consumption
--@param show bool, show or hide the stats on screen. default is true
--@param forceGarbageOnTouch bool. If stats are shown, if true force garbage collector on touch. default is false
function Shilke2D:showStats(show, forceGarbageOnTouch)
	local show = not (show == false)
	local forceGarbageOnTouch = forceGarbageOnTouch == true
	
	self._showStats = show 
	self._statsForceGarbage = forceGarbageOnTouch
	if show and #self._renderTable == 2 then
		self._renderTable[3] = self.stats._renderTable
	elseif not show and #self._renderTable == 3 then
		self._renderTable[3] = nil
	end
end

--[[---
Any DisplayObj can register itself as owner (unique listener) for a specific 
touch (id) event. 
That's used to manage drag and drop logic. When the touch ends the object is automatically removed
as listener. The object can release itself event if the touch is not still ended by calling stopDrag
method.
--]]
function Shilke2D:startDrag(touch,obj)
    self.ownedTouches[touch.id] = obj
end

--[[---
An object can deregister itself as unique listener for a specific
touch (id) event.
If the object was not registered as listener an error raises.
--]]
function Shilke2D:stopDrag(touch,obj)
    if self.ownedTouches[touch.id] ~= obj then
        error("displayObj is not set as owner for this touch")
    end
    self.ownedTouches[touch.id] = nil
end

---Returns the object that owns a specific touch (id)
-- @param touch the touch for which we want to get the owner
-- @return the owner of the provided touch. nil if no object is registered as owner of this touch.
function Shilke2D:getDraggedObj(touch)
	return self.ownedTouches[touch.id]
end

