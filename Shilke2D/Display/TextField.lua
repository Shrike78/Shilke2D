-- TextField
-- Extend to be similar to Original Starling Textfield

TextField = class(FixedSizeObject)

--At initialization phase it preload a default system font
local function loadSystemFont()
	local font = MOAIFont.new()
	local charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&/-'
	--fonts are correctly loaded because it's done at the beginning of the initialization phase
	--font:loadFromTTF("Shilke2D/Resources/times.ttf",charcodes,16)
	font:loadFromTTF("Shilke2D/Resources/arial-rounded.TTF",charcodes,16)
	return font
end

TextField.__systemFont = loadSystemFont()

function TextField:init(width, height, font, fontSize, text, pivotMode)
	FixedSizeObject.init(self,width,height,pivotMode)
	
if __USE_SIMULATION_COORDS__  then
    self._prop:setYFlip ( true )
end
	self._prop:setRect(-self._width/2,-self._height/2,self._width/2,self._height/2)

	local font = font or TextField.__systemFont
	local fontSize = fontSize or 16
	self.text = text or ""
	
	self:setFont(font,fontSize)
	self:setText(self.text)
end

--Create a textbox as inner prop
function TextField:_createProp()
	return MOAITextBox.new()
end

function TextField:setSize(width,height)
	FixedSizeObject.setSize(self,width,height)
    self._prop:setRect(-width/2, -height/2, width/2, height/2)
end

function TextField:setFont(font,size)
	local _font
	if type(font) == 'string' then
		_font = MOAIFont.new()
		_font:load(font)
	else
		_font = font
	end
	self._prop:setFont(_font)
	if size then
		self._prop:setTextSize(size)
	end
	return self
end

function TextField:setText(text)
	self.text = text or ""
	self._prop:setString(self.text)
	return self
end


--return the bounding rect around the text
function TextField:getTextBound(resultRect,targetSpace)
	local r = resultRect or Rect()
	local xmin,ymin,xmax,ymax = self._prop:getStringBounds(1,self.text:len())
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

--return a poly/quad oriented depending on targetSpace
function TextField:getOrientedTextBound(targetSpace)
	local xmin,ymin,xmax,ymax = self._prop:getStringBounds(1,self.text:len())
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
