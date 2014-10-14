--[[---
Stats helper to show on screen framerate, memory occupation, ecc.
Displayed infos are:

Fps - DrawCalls - Total Memory (lua memory, texture memory)
--]]
Stats = class(DisplayObjContainer)

function Stats:init()
	DisplayObjContainer.init(self)
	
	local background = Quad(300,20)
	background:setColor(Color(0,0,0))
	self:addChild(background)
	
	self.info_stats = TextField(300,20, "")
	self.info_stats:setAlignment(MOAITextBox.CENTER_JUSTIFY)
	self:addChild(self.info_stats)
end


--[[---
Updates with the last frame informations
--]]
function Stats:update()	
	local fps = math.floor(MOAISim.getPerformance())
	local usage = MOAISim.getMemoryUsage()
	local mtotal = usage.total/(1024*1024)
	local mlua = usage.lua/(1024*1024)
	local mtexture = usage.texture/(1024*1024)
	--keep 1 that's the cost of drawing Stats object itself
	local drawcalls = MOAIRenderMgr.getPerformanceDrawCount() - 1
	self.info_stats:setText(string.format("%d - %d - %.3f (%.3f, %.3f)", fps, drawcalls, mtotal, mlua, mtexture))
end

