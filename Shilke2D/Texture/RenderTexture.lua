--[[---
A RenderTexture is a dynamic texture onto which you can draw a display object.

After creating a render texture, just call a draw* methods to render a display object 
directly onto the texture.

The RenderTexure is created with a specific width / height, so the rendering will be limited to 
a rectangle of (0,0,width,height).

The displayObj to be rendered will keep it local geometrical and color properties when rendered.

i.e. if an image wiht PivotMode.CENTER, placed in 0,0, not rotated and not scaled is rendered, 
the resulting texture will shown just a part of the texture (which one depends by choosed coordinate 
system) 

Draw Methods:

- drawObject(object, callback): most common method, used to draw a generic display obj

- drawDynamicObject(object, callback): used to update each frame the texture. Can be used with animated
objects.

- drawRenderTable(object, bUpdate, callback): can be used with a generic MOAI rendertable. bUpdate param
let choose to render only first frame or to have a continuous update.

--]]


--[[---
Returns a RenderTexture of a given displayObj.
@param displayObj the displayObj that must be rendered on the newly created texture. The provided displayObj
must have no parent
@param requireSrcData optional boolean value. If local image is required for getColor / hitTest logic
set it to true. default value is false
@param callback optional callback function called after the render to texture has been completed. 
If requireSrcData is true then the callback is called after the srcData is acquired
@treturn RenderTexture the returned texture can be used istantly (i.e. to create an Image) even if 
the render to texture will happen next frame
--]]
function Texture.fromDisplayObj(displayObj, requireSrcData, callback)
	assert(displayObj:getParent() == nil)
	local rt = RenderTexture(displayObj:getSize())
	if not requireSrcData then
		rt:drawObject(displayObj, callback)
	else
		rt:drawObject(displayObj)
		rt:syncSrcData(callback)
	end
	return rt
end


RenderTexture = class(Texture)

--[[---
Constructor. Create a frameBuffer of size(width,height)
@tparam int width 
@tparam int height
@tparam[opt=nil] Rect frame
--]]
function RenderTexture:init(width,height, frame)
	assert(width<=Texture.MAX_WIDTH, width .. " not allowed, max is" .. Texture.MAX_WIDTH)
	assert(height<=Texture.MAX_HEIGHT, height .. " not allowed, max is" .. Texture.MAX_HEIGHT)
	
	local width = math.min(width, Texture.MAX_WIDTH)
	local height = math.min(height, Texture.MAX_HEIGHT)
	
	self.srcData = nil
	self.textureData, self.layer = nil,nil
	self:_createFrameBuffer(width, height)
	
	self.scriptDeck = MOAIScriptDeck.new()
	self.scriptProp = MOAIProp.new()
	self.scriptProp:setDeck(self.scriptDeck)

	self.rotated = false
	self.trimmed = frame ~= nil
	self.region = Rect(0,0,	self.textureData:getSize())
	self.frame = frame or self.region
end

--[[---
clear all the structures and relase the frameBuffer
--]]
function RenderTexture:dispose()
	self:_destroyFrameBuffer()
	self.textureData:release()
	self.textureData = nil
	self.scriptProp = nil
	self.scriptDeck = nil
	self.srcData = nil
	self.region = nil
	self.frame = nil
end

--[[---
Inner method. Creates a frameBuffer of a given size and a layer with an according viewport
@tparam number width
@tparam number height
--]]
function RenderTexture:_createFrameBuffer(width,height)
	assert( not self.textureData, "_createFrameBuffer has already been called")
	--create a new viewport with required width / height
	local viewport = MOAIViewport.new()
	if __USE_SIMULATION_COORDS__ then
		viewport:setScale(width, -height)
		viewport:setSize(width, height)
		viewport:setOffset(-1, 1)
	else
		viewport:setScale(width, height)
		viewport:setSize(width, height)
		viewport:setOffset(-1, -1)
	end
	
	--create a new layer for viewport and 'subscene' management
	local layer = MOAILayer.new()
	layer:setViewport(viewport)
		
	--create the framebuffer with its specific rendertable
	local frameBuffer = MOAIFrameBufferTexture.new()
	frameBuffer:init( width, height )
	--the clear color is set to transparent color
	frameBuffer:setClearColor( 0, 0, 0, 0 )
	
	self.textureData, self.layer = frameBuffer, layer
end

--[[---
Inner method. Destroy the frameBuffer, clear the layer and release all the structures
--]]
function RenderTexture:_destroyFrameBuffer()
	assert( self.textureData, "_createFrameBuffer has never been called")
	self:_removeFrameBuffer()
	self.textureData:setRenderTable(nil)
	self.layer:clear()
	self.layer = nil
end

--- Inner method. 
--Used to add the wrapped frameBuffer to the Shilke2D render frameBuffer table
function RenderTexture:_addFrameBuffer()
	if table.find(Shilke2D.__frameBufferTables, self.textureData) == 0 then
		--print("add framebuffer")
		table.insert(Shilke2D.__frameBufferTables, self.textureData)
		MOAIRenderMgr.setBufferTable(Shilke2D.__frameBufferTables)
	end

end

--- Inner method. 
--Used to remove the wrapped frameBuffer from the Shilke2D render frameBuffer table
function RenderTexture:_removeFrameBuffer()
	if table.removeObj(Shilke2D.__frameBufferTables, self.textureData) then
		--print("remove framebuffer")
		MOAIRenderMgr.setBufferTable(Shilke2D.__frameBufferTables)
	end
end

--[[---
Draw a DisplayObj onto the wrapped frameBuffer.
If a callback is provided that will be called after the render to texture is completed.
@param displayObj
@param callback
--]]
function RenderTexture:drawObject(displayObj, callback)
	self:drawRenderTable(displayObj._renderTable, false, callback)
end

--[[---
Draw a DisplayObj onto the wrapped frameBuffer. The render to texture is done every frame,
so it should be used only with an animated displayObj and in very particular situation (i.e. if 
a shader must be used over a generic displayObject animation)
If a callback is provided that will be called after the first render to texture is completed.
@param displayObj
@param callback
--]]
function RenderTexture:drawDynamicObject(displayObj, callback)
	self:drawRenderTable(displayObj._renderTable, true, callback)
end

--[[---
Draw a valid MOAI rendertable onty the wrapped frameBuffer. if bUpdate is true the render to texture
is done every frame, else just the first one.
If a callback is provided that will be called after the first render to texture is completed.
@param renderTable
@tparam boolean continuousUpdate if true the render to texture is done every frame
@param callback
--]]
function RenderTexture:drawRenderTable(renderTable, continuousUpdate, callback)
	self.continuousUpdate = continuousUpdate
	assert(not callback or is_function(callback), "the provided param is not a function type")
	self.scriptDeck:setDrawCallback(function()
			--remove the script deck: the callback must be call only at first update
			self.textureData:setRenderTable({self.layer, renderTable})
			if not self.continuousUpdate then
				self:_removeFrameBuffer()
			end
			if callback then
				callback(self)
			end
		end
	)
	self:_addFrameBuffer()
	self.textureData:setRenderTable({self.layer, renderTable, self.scriptProp})
end

--[[---
Asynchronously grabs the next frame of the wrapped framebuffer. The frame is then returned 
to the caller throug a callback. The frame can be returned as a Texture (default behaviour) or as
a raw MOAIImage data (if bRawData is true).

The call forces also an update of the wrapped frameBuffer (if continuousUpdate was false)and 
requires the rendertable provided in draw method to be still available. If a change has occurred 
in the rendertable the texture will be changed accordingly

@param callback a function of type callFunc(sender, texture) or callFunc(sender, MOAIImage) 
if bRawData is set. The callback receive as param the newly generated Texture / MOAIImage.
@param bRawData optional, default false. By default grabNextFrame generates a Texture. If true it 
returns a raw MOAIImage data
--]]
function RenderTexture:grabNextFrame(callback, bRawData)
	assert(is_function(callback), "a callback function must be provided")
	local fbSrcData = MOAIImage.new()
	local cbFunc = function()
		if not self.continuousUpdate then
			self:_removeFrameBuffer()
		end
		if bRawData then
			callback(self, fbSrcData)
		else
			local t = Texture.fromData(fbSrcData)
			callback(self, t)
		end
	end
	if not self.continuousUpdate then
		self:_addFrameBuffer()
	end
	self.textureData:grabNextFrame(fbSrcData, cbFunc)
end


--[[---
This method force to grab the next frame of the wrapped frameBuffer and use it as srcData. 
That can be usefull if the RenderTexture must be used for pixel precision collision test or
if a per pixel color information is required. It's possible to provide a callback that will
be called after frame grab. 

The call forces also an update of the wrapped frameBuffer (if continuousUpdate was false)and 
requires the rendertable provided in draw method to be still available. If a change has occurred 
in the rendertable the texture will be changed accordingly.

@param callback optional callback function in the form of callback(sender)

--]]
function RenderTexture:syncSrcData(callback)
	local cbFunc = function(sender, srcData)
		self.srcData = srcData
		if callback then
			callback(sender)
		end
	end
	self:grabNextFrame(cbFunc, true)
end


