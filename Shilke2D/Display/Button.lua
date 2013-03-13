-- Button
--[[
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

function Button:init(upState, label, downState)
    DisplayObjContainer.init(self)
    if not upState then
        error("upState texture cannot be null")
    end
    
    self.upState = upState;
    self.downState = downState and downState or upState
    print(self.downState)
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
		error("Button with TextField not correctly implemented")
		--[[
        self.textField = TextField(upState.width,upState.height,label,
            nil,nil,PivotMode.CENTER)
        self.textField:setPosition(self.textField:getWidth()/2,
            self.textField:getHeight()/2)
        self.contents:addChild(self.textField)
		--]]
    end
    self:setHittable(true)
    self:addEventListener(Event.TOUCH, Button.onTouch,self)        
end

function Button:resetContents()
    self.isDown = false
    self.background:setTexture(self.upState)
    self.contents:setPosition(0,0)
    self.contents:setScale(1,1)
end

function Button:getTextField()
    return self.textField
end

function Button:setName(name)
    DisplayObjContainer.setName(self,name)
    self.contents:setName(name.."_contents")
end

-- The scale factor of the button on touch. Per default, 
-- a button with a down state texture won't scale.
function Button:getScaleWhenDown()
    return self.scaleWhenDown
end

function Button:setScaleWhenDown(value)
    self.scaleWhenDown = value
end
        
-- The alpha value of the button when it is disabled. 
-- default = 0.5
function Button:getAlphaWhenDisabled()
    return self.alphaWhenDisabled
end
       
function Button:setAlphaWhenDisabled(value)
    self.alphaWhenDisabled = value
end
        
-- Indicates if the button can be triggered.
function Button:isEnabled()
    return self.enabled
end
        
function Button:setEnabled(value)
    if (self.enabled ~= value) then
        self.enabled = value
        local a = value and 255 or self.alphaWhenDisabled
        self.contents:setAlpha(a)
        self:resetContents()
    end
end

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
            self:dispatchEvent(Event(Event.TRIGGERED))
        end
    end
end
