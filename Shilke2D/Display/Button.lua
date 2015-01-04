--[[---
A simple button composed of an image and, optionally, text. 

It's possible to set a texture for up and downstate of the button.
If a down state is not provided the button is simply scaled a 
little when it is touched.

In addition, you can overlay a text on the button. To customize the 
text, almost the same options as those of text fields are provided. 
      
To react on touches on a button, there is special triggered-event type,
dispatched when the touch.state is ENDED and the button was hitted
--]]
Button = class(DisplayObjContainer)

--[[---
Creates a button with textures for upState, downState or text.
@param upState a texture to be used for the up state
@param downState (optional) a texture to be used for the down state. If nil
the upState texture will be used, but scaled of a factor of 0.9
@param label (optional) a text to be added to the button
--]]
function Button:init(upState, downState, label)
    DisplayObjContainer.init(self)
    if not upState then
        error("upState texture cannot be null")
    end
    
    self.upState = upState;
    self.downState = downState and downState or upState
    self.background = Image(upState)
    self.background:setPosition(self.background:getWidth()/2, 
        self.background:getHeight()/2)
    self.scaleWhenDown = downState and 1 or 0.9
    self.alphaWhenDisabled = 128
    self.enabled = true
    self.isDown = false
    
    self.contents = DisplayObjContainer()
    self.contents:addChild(self.background)
    self:addChild(self.contents)
    if label then
        self.textField = TextField(upState:getWidth(),upState:getHeight(),label,nil,nil,
            PivotMode.CENTER)
        self.textField:setPosition(self.textField:getWidth()/2,
			self.textField:getHeight()/2)
        self.contents:addChild(self.textField)
    end
    self:setHittable(true)
    self:addEventListener(Event.TOUCH, Button.onTouch, self)        
end

---Resets button state at default values
function Button:resetContents()
    self.isDown = false
    self.background:setTexture(self.upState)
    self.contents:setPosition(0,0)
    self.contents:setScale(1,1)
end

---Returns the textfield (if it exists)
--@return TextField or nil
function Button:getTextField()
    return self.textField
end


function Button:getUpState()
	return self.upState
end

function Button:getDownState()
	return self.downState
end

function Button:getLabel()
	return self.textField and self.textField:getText() or ""
end


---The scale factor of the button on touch. Per default, 
--a button with a down state texture won't scale.
--@return scale value
function Button:getScaleWhenDown()
    return self.scaleWhenDown
end

---The scale factor of the button on touch. Per default, 
--a button with a down state texture won't scale.
--@param value scale value
function Button:setScaleWhenDown(value)
    self.scaleWhenDown = value
end
        
---The alpha value of the button when it is disabled. 
--default = 128
--@return alpha value [0,255]
function Button:getAlphaWhenDisabled()
    return self.alphaWhenDisabled
end
       
---The alpha value of the button when it is disabled. 
--default = 128
--@param value [0,255]
function Button:setAlphaWhenDisabled(value)
    self.alphaWhenDisabled = value
end
        
---Indicates if the button can be triggered.
--@return bool
function Button:isEnabled()
    return self.enabled
end
		
---Enable/Disable button.
--@param value boolean
function Button:setEnabled(value)
    if (self.enabled ~= value) then
        self.enabled = value
        local a = value and 255 or self.alphaWhenDisabled
        self.contents:setAlpha(a)
        self:resetContents()
    end
end

---Inner method used to handle touch event and translate it into a trigger event when
--touch is released
--@param e touch event
function Button:onTouch(e)
    if not self.enabled then
        return 
    end
    
    local touch = e.touch
    
    if (touch.state == Touch.BEGAN or touch.state == Touch.MOVING)
            and not self.isDown then
                
        self.background:setTexture(self.downState)
        self.contents:setScale(self.scaleWhenDown,self.scaleWhenDown)
        self.isDown = true
        
    elseif touch.state == Touch.MOVING and self.isDown then
        if e.target ~= self then
            self:resetContents()
        end
        
    elseif touch.state == Touch.ENDED and self.isDown then
        
        self:resetContents()
        if e.target == self then
            self:dispatchEventByType(Event.TRIGGERED)
        end
    end
end
