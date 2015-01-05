--[[---
MOAIVersion exposes an enum with MOAI sdk versions that changes compatibility or add 
new features used by Shilke2D.

This way Shilke2D can support different moai sdk versions, but some features have 
different implementation depending on sdk version.
--]]

---Supported MOAI Sdk versions
MOAIVersion = 
{
	v1_3 = 0,
	v1_4 = 1,
	v1_5 = 2
}

---Current moai version.
MOAIVersion.current = -1

if MOAIProp.getInterfaceTable().isVisible then
	--[[
	v1.5 add the following changes used by Shilke2D:
	- MOAIProp:isVisible()
	- MOAITextBox:getAlignment()
	- different behavior for moai setInterface call (MOAI_class implementation)
	--]]
	MOAIVersion.current = MOAIVersion.v1_5

elseif MOAIGfxDevice.getFrameBuffer then
	-- clear color moved from gfxdevice to frame buffer 
	MOAIVersion.current = MOAIVersion.v1_4
else
	MOAIVersion.current = MOAIVersion.v1_3
end
	
