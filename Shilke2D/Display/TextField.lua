--[[---
A TextField is a particolar displayObject used to displays text.
It inherits from baseQuad so supports pivotMode logic

Current implementation allows to use only standard true type fonts.
--]]
TextField = class(BaseQuad)

---Used to align vertically or horizontally the text
TextField.CENTER_JUSTIFY = MOAITextBox.CENTER_JUSTIFY

---Used to align horizontally the text
TextField.LEFT_JUSTIFY = MOAITextBox.LEFT_JUSTIFY
---Used to align horizontally the text
TextField.RIGHT_JUSTIFY = MOAITextBox.RIGHT_JUSTIFY

---Used to align vertically the text
TextField.TOP_JUSTIFY = MOAITextBox.LEFT_JUSTIFY
---Used to align vertically the text
TextField.BOTTOM_JUSTIFY = MOAITextBox.RIGHT_JUSTIFY

---Called at initialization phase, before Shilke2D is started.
--It preloads a default system font
local function loadSystemFont()
	local font = MOAIFont.new()
	local charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-'
	--fonts are correctly loaded because it's done at the beginning of the initialization phase
	--font:loadFromTTF("Shilke2D/Resources/times.ttf",charcodes,16)
	font:loadFromTTF("Shilke2D/Resources/arial-rounded.TTF",charcodes,16)
	return font
end



TextField.__systemFont = loadSystemFont()

--[[---
Constructor
@param width width of the textfield.
@param height height of the textfield.
@param text the text displayed by the textfield.
@param font font to be used. If nil defaul font will be used
@param fontSize fontSize. default is 16
@param pivotMode defaul value is CENTER
--]]
function TextField:init(width, height, text, font, fontSize, pivotMode)
	BaseQuad.init(self,width,height,pivotMode)
	
if __USE_SIMULATION_COORDS__  then
    self._prop:setYFlip ( true )
end

	self._prop:setRect(0,0,self._width,self._height)

	self._font = font or TextField.__systemFont
	self._fontSize = fontSize or 16
	self._text = text or ""
	
	self:setAlignment(TextField.LEFT_JUSTIFY,TextField.TOP_JUSTIFY)
	
	
	self:setFont(self._font, self._fontSize)
	self:setText(self._text)
end


---Creates a MOAITextBox as inner prop
--@return MOAITextBox
function TextField:_createProp()
	return MOAITextBox.new()
end

---Sets horizontal and vertical alignment
--@param hAlign  
--@param vAlign 
function TextField:setAlignment(hAlign, vAlign)
	self.hAlign = hAlign
	self.vAlign = vAlign
	self._prop:setAlignment( self.hAlign, self.vAlign)
end

---Returns horizontal and vertical alignment
--@return hAlign  
--@return vAlign 
function TextField:getAlignment()
	return self.hAlign, self.vAlign
end

---Sets horizontal alignment
--@param hAlign
function TextField:setHAlignement(hAlign)
	self.hAlign = hAlign
	self._prop:setAlignment(self.hAlign, self.vAlign)
end

---Returns horizontal alignment
--@return hAlign  
function TextField:getHAlignment()
	return self.hAlign
end

---Sets vertical alignment
--@param vAlign
function TextField:setVAlignement(vAlign)
	self.vAlign = vAlign
	self._prop:setAlignment( self.hAlign, self.vAlign)
end

---Returns vertical alignment
--@return vAlign  
function TextField:getVAlignment()
	return self.vAlign
end

---Sets size of the textfield
--@param width
--@param height
function TextField:setSize(width,height)
	BaseQuad.setSize(self,width,height)
    self._prop:setRect(0, 0, width, height)
end

---Sets font
--@param font name or font object
--@param size optional, if not provided is not updated
function TextField:setFont(font,size)
	if type(font) == 'string' then
		self._font = MOAIFont.new()
		self._font:load(font)
	else
		self._font = font
	end
	self._prop:setFont(self._font)
	if size then
		self._fontSize = size
		self._prop:setTextSize(self._fontSize)
	end
	return self
end

---Gets font
--@return font used font
--@return size used font size
function TextField:getFont()
	return self._font, self._fontSize
end

---Sets font size
--@param size
function TextField:setFontSize(size)
	self._fontSize = size
	self._prop:setTextSize(self._fontSize)
	return self
end

---Gets font size
--@return size current font size
function TextField:getFontSize()
	return self._fontSize
end

---Sets the text to be displayed
--@param text if nil is replaced by ""
function TextField:setText(text)
	self._text = text or ""
	self._prop:setString(self._text)
	return self
end

---Gets the displayed text 
--@return text current displayed text
function TextField:getText()
	return self._text
end

---Returns the bounding rect around the text related to a specific coordinate system
--@param resultRect if provided uses it instead of creating a new Rect
--@param targetSpace if nil refers to the top most container (usually the stage)
--@return Rect
function TextField:getTextBound(resultRect,targetSpace)
	local r = resultRect or Rect()
	local xmin,ymin,xmax,ymax = self._prop:getStringBounds(1,self._text:len())
	if targetSpace ~= self then
        self:updateTransformationMatrix(targetSpace)
	    
		local _rect = {	{xmin, ymin }, {xmin, ymax }, {xmax, ymax}, {xmax, ymin }}
        local x,y
		
        for i = 1,4 do
            x,y = self._transformMatrix:modelToWorld(_rect[i][1],_rect[i][2],0)      
            xmin = min(xmin,x)
            xmax = max(xmax,x)
            ymin = min(ymin,y)
            ymax = max(ymax,y)
        end
	end
	r.x, r.y, r.w, r.h = xmin, ymin, xmax-xmin, ymax-ymin
	return r
end

---Returns a poly/quad oriented depending on targetSpace
--@param targetSpace if nil refers to the top most container (usually the stage)
--@return a list of point expressed as x,y [x,y,....] with the last point as a replica of the first one.
--The result can be used with a MOAIDraw.drawLine call
function TextField:getOrientedTextBound(targetSpace)
	local xmin,ymin,xmax,ymax = self._prop:getStringBounds(1,self._text:len())
	local q = {xmin,ymin,xmax,ymin,xmax,ymax,xmin,ymax}
	if targetSpace ~= self then
        self:updateTransformationMatrix(targetSpace)
		for i = 0,3 do
			q[i*2+1],q[i*2+2] = self._transformMatrix:modelToWorld(q[i*2+1],q[i*2+2])
		end
	end
	q[#q+1] = q[1]
	q[#q+1] = q[2]
	return unpack(q)
end
