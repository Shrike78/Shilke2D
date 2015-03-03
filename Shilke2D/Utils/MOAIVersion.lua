--[[---
MOAIVersion exposes an enum with MOAI sdk versions that changes compatibility or add 
new features used by Shilke2D.

This way Shilke2D can support different moai sdk versions, but some features have 
different implementation depending on sdk version.

The module expose also a set of functions to make transparent the current used module
--]]
	
---
-- Supported MOAI Sdk versions
MOAIVersion = 
{
	v1_3 = 1,
	v1_4 = 2,
	v1_5_1 = 3,
	v1_5_2 = 4
}

---
-- Current moai version.
MOAIVersion.current = -1

if MOAIColor.getInterfaceTable().getColor then
	
	-- list of v1.5.2 new functionalities:
	-- MOAIColor:getColor
	MOAIVersion.current = MOAIVersion.v1_5_2

elseif MOAIProp.getInterfaceTable().isVisible then

	-- list of v1.5.1 new functionalities:
	-- MOAIProp:isVisible()
	-- MOAITextBox:getAlignment()
	-- Different behavior for moai setInterface call
	MOAIVersion.current = MOAIVersion.v1_5_1

elseif MOAIGfxDevice.getFrameBuffer then

	-- list of v1.4 new functionalities:
	-- clear color moved from gfxdevice to frame buffer 
	MOAIVersion.current = MOAIVersion.v1_4

else

	MOAIVersion.current = MOAIVersion.v1_3

end
	

if MOAIVersion.current < MOAIVersion.v1_4 then
	
	---
	-- Set the screen clear color
	-- @function MOAI_setClearColor
	-- @tparam number r (0,1)
	-- @tparam number g (0,1)
	-- @tparam number b (0,1)
	-- @tparam number a (0,1)
	MOAI_setClearColor = function(r,g,b,a)
		MOAIGfxDevice.setClearColor(r,g,b,a)
	end
	
else
	
	MOAI_setClearColor = function(r,g,b,a)
		MOAIGfxDevice.getFrameBuffer():setClearColor(r,g,b,a)
	end

end


if MOAIVersion.current < MOAIVersion.v1_5_1 then
	
	---
	-- Get the visibility status of a moai prop
	-- @tparam MOAIProp moai_prop the moai prop object
	-- @treturn bool
	function MOAI_isVisible(moai_prop)
		return moai_prop:getAttr(MOAIProp.ATTR_VISIBLE) > 0
	end
	
else
	
	MOAI_isVisible = MOAIProp.getInterfaceTable().isVisible	

end

if MOAIVersion.current < MOAIVersion.v1_5_2 then
	
	---
	-- Get the color of a MOAIColor object
	-- @tparam MOAIColor moai_color the moai color object
	-- @treturn number r (0,1)
	-- @treturn number g (0,1)
	-- @treturn number b (0,1)
	-- @treturn number a (0,1)
	function MOAI_getColor(moai_color)
		local r = moai_color:getAttr(MOAIColor.ATTR_R_COL)
		local g = moai_color:getAttr(MOAIColor.ATTR_G_COL)
		local b = moai_color:getAttr(MOAIColor.ATTR_B_COL)
		local a = moai_color:getAttr(MOAIColor.ATTR_A_COL)
		return r,g,b,a
	end
		
else
	
	MOAI_getColor = MOAIColor.getInterfaceTable().getColor
	
end

---
-- Create a moai property of type T. 
-- On old sdk add the isVisible and getColor 
-- method to newly created property (expecting T 
-- as a color prop)
-- @param T type of the moai prop to create (expects to be a color prop)
-- @return MOAIProp of type T
function createMoaiProp(T)
	local p = T.new()
	-- Do not check moai version / method existance. 
	-- If isVisible and getColor functions are already defined
	-- resetting to themself has no effect at all
	p.isVisible = MOAI_isVisible
	p.getColor = MOAI_getColor
	return p
end

