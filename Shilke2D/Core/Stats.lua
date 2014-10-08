--[[---
Stats helper to show on screen framerate, memory occupation, ecc.
--]]
Stats = class(DisplayObjContainer)

function Stats:init()
	DisplayObjContainer.init(self)
	
	local background = Quad(150,20)
	background:setColor(Color(0,0,0))
	self:addChild(background)
	
	self.info_stats = TextField(150,20, "")
	self.info_stats:setAlignment(MOAITextBox.CENTER_JUSTIFY)
	self:addChild(self.info_stats)
end


--[[---
Updates with the last frame informations
--]]
function Stats:update()	
	local fps = math.floor(MOAISim.getPerformance())
	local usage = MOAISim.getMemoryUsage()
	--local drawcalls = MOAIRenderMgr.getPerformanceDrawCount()
	--self.info_stats:setText(string.format("%d - %d - %d", fps, usage.total, drawcalls))
	self.info_stats:setText(string.format("%d - %d", fps, usage.total))
end

