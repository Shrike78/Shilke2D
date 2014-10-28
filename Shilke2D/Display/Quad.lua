--[[---
A Quad represents a rectangle with a uniform color or a color gradient.
It's possible to set one color per vertex. The colors will smoothly 
fade into each other over the area of the quad. To display a simple 
linear color gradient, assign one color to vertices 1 and 2 and 
another color to vertices 3 and 4. 

if __USE_SIMULATION_COORDS__ is nil or false then vertex 1 is the top left one, 
and the vertices follow clockwise order.

if __USE_SIMULATION_COORDS__ is true then vertex 1 is the bottom left one, 
and the vertices follow counter clockwise order.
--]]

--basic math function calls
local INV_255 = 1/255

--default quad shader, created first time a quad is created
local _quad_shader = nil

Quad = class(BaseQuad)

---Quad are drawn using a pixel shader so it's necessary to have
--it enabled to inherits ancestors color values
Quad.__defaultUseMultiplyColor = true

--[[---
Constructor.
@param width quad width
@param height quad height
@param pivotMode optional, defaul value is CENTER
--]]
function Quad:init(width,height,pivotMode)
	BaseQuad.init(self,width,height,pivotMode)
	
	--use the base color as first of the 4 colors of the quad
	self._colors = {self._color,
					{1,1,1,1},
					{1,1,1,1},
					{1,1,1,1}}
	
	self:_createMesh()
	self:_updateVertexBuffer()
	
	self._prop:setDeck(self._mesh)
end


---override default quad shader
--@tparam MOAIShader shader
function Quad:setShader(shader)
	if shader then
		self._prop:setShader(shader)
	else
		self._prop:setShader(_quad_shader)
	end
end


---Inner method. It creates the quad mesh that will be displayed
function Quad:_createMesh()
		
	local vertexFormat = MOAIVertexFormat.new ()
	vertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 2 )
	vertexFormat:declareColor ( 2, MOAIVertexFormat.GL_UNSIGNED_BYTE )

	self._vbo = MOAIVertexBuffer.new ()
	self._vbo:setFormat ( vertexFormat )
	self._vbo:reserveVerts ( 4 )

	self._mesh = MOAIMesh.new ()
	self._mesh:setVertexBuffer ( self._vbo )
	self._mesh:setPrimType ( MOAIMesh.GL_TRIANGLE_FAN )
	if not _quad_shader then
		_quad_shader = MOAIShader.new ()
		local vsh = IO.getFile("/Shilke2D/Resources/quad.vsh")
		local fsh = IO.getFile("/Shilke2D/Resources/quad.fsh")
		_quad_shader:reserveUniforms(2)
		_quad_shader:declareUniform(1, 'transform', MOAIShader.UNIFORM_WORLD_VIEW_PROJ )
		_quad_shader:declareUniform(2, 'ucolor', MOAIShader.UNIFORM_PEN_COLOR )

		_quad_shader:setVertexAttribute ( 1, 'position' )
		_quad_shader:setVertexAttribute ( 2, 'color' )
		_quad_shader:load ( vsh, fsh )
	end
	
	self._mesh:setShader(_quad_shader)
end

---Inner methods. 
--Called everytime geometric or color information are changed, 
--to update mesh vertices infos.
function Quad:_updateVertexBuffer()
	
	local vcoords = {{ 0, 0 },
					{ self._width, 0 },
					{ self._width, self._height },
					{ 0, self._height }}
	
	self._vbo:reset()
	
	local mc = self._multiplyColor
	local c,a
	for i=1, #vcoords do
		-- write vertex position
		self._vbo:writeFloat ( vcoords[i][1], vcoords[i][2] )              
		-- write RGBA value
		c = self._colors[i]
		if self._premultipliedAlpha then
			a = c[4] * mc[4]
			self._vbo:writeColor32(
						c[1] * mc[1] * a, 
						c[2] * mc[2] * a, 
						c[3] * mc[3] * a, 
						a
					)
		else
			self._vbo:writeColor32(
						c[1] * mc[1], 
						c[2] * mc[2], 
						c[3] * mc[3], 
						c[4] * mc[4]
					)
		end
	end
    
	self._vbo:bless ()	

end

---Set the size of the quad
--@param width quad width
--@param height quad height
function Quad:setSize(width,height)
	BaseQuad.setSize(self,width,height)
	self:_updateVertexBuffer()
end

--[[---
Override base method. It calls _updateVertexBuffer
@param r [0,1]
@param g [0,1]
@param b [0,1]
@param a [0,1]
--]]
function Quad:_setMultiplyColor(r,g,b,a)
	local mc = self._multiplyColor
	mc[1] = r
	mc[2] = g
	mc[3] = b
	mc[4] = a
	self:_updateVertexBuffer()
end

---Returns the multiplied alpha value as applied to the first vertex. 
--If alpha values is different per vertices the return value has no real meaning
--@return int obtained by Color.rgba2int([0,255],[0,255],[0,255],[0,255])
function Quad:_getMultipliedColor()
	local mc = self._multiplyColor
	local r = mc[1] * self._colors[1][1]  
	local g = mc[2] * self._colors[1][2]  
	local b = mc[3] * self._colors[1][3]  
	local a = mc[4] * self._colors[1][4]
	return r,g,b,a
end

---overrides displayobj method redirecting on _updateVertexBuffer
--that already does the same thing for quads
function Quad:_updateColor()
	self:_updateVertexBuffer()
end

---Override base method. It calls _updateVertexBuffer
--@param a alpha value [0,255]
function Quad:setAlpha(a)
    for i = 1,4 do
        self._colors[i][4] = a * INV_255
    end
    self:_updateVertexBuffer()
end

---Returns the alpha value as set at the first vertex. 
--If alpha values is different per vertices the return value has no real meaning
--@return alpha value [0,255]
function Quad:getAlpha()
   return self._colors[1][4]*255
end


---Set alpha value for a single vertex
--@param v index of the vertex [1,4]
--@param a alpha value [0,255]
function Quad:setVertexAlpha(v,a) 
	self._colors[v][4] = a * INV_255
	self:_updateVertexBuffer()
end

---Returns alpha value of a single vertex
--@param v index of the vertex [1,4]
--@return alpha value [0,255]
function Quad:getVertexAlpha(v)
   return self._colors[v][4]*255
end

--[[---
Set obj color.
@function Quad:setColor
@tparam Color color
--]]

--[[---
Set obj color.
@function Quad:setColor
@tparam string hex hex string color
--]]

--[[---
Set obj color.
@tparam int r (0,255)
@tparam int g (0,255)
@tparam int b (0,255)
@tparam[opt=255] int a (0,255)
--]]
function Quad:setColor(r,g,b,a)
	local r,g,b,a = Color._paramConversion(r,g,b,a,self._colors[1][4])	
	for i = 1,4 do
		self._colors[i][1] = r
		self._colors[i][2] = g
		self._colors[i][3] = b
		self._colors[i][4] = a
	end
	self:_updateVertexBuffer()
end

---Returns the color of the first vertex. 
--If color value is per vertices the return value has no real meaning
--@return Color
function Quad:getColor()
	return Color.fromNormalizedValues(unpack(self._colors[1]))
end

--[[---
Set vertex color.
@function Quad:setVertexColor
@tparam int v vertex index (1,4)
@tparam Color color
--]]

--[[---
Set vertex color.
@function Quad:setVertexColor
@tparam int v vertex index (1,4)
@tparam string hex hex string color
--]]

--[[---
Set vertex color.
@function Quad:setVertexColor
@tparam int v vertex index (1,4)
@tparam int r (0,255)
@tparam int g (0,255)
@tparam int b (0,255)
@tparam[opt=255] int a (0,255)
--]]
function Quad:setVertexColor(v,r,g,b,a) 
	local c = self._colors[v]
	c[1], c[2], c[3], c[4] = Color._paramConversion(r,g,b,a,c[4])
	self:_updateVertexBuffer()
end

---Returns vertext color of a single vertex
--@param v index of the vertex [1,4]
--@return Color
function Quad:getVertexColor(v)
  return Color.fromNormalizedValues(unpack(self._colors[v]))
end

---Sets all the colors of the 4 vertices
--@param c1 Color of vertex1
--@param c2 Color of vertex2
--@param c3 Color of vertex3
--@param c4 Color of vertex4
function Quad:setColors(c1,c2,c3,c4)
	local colors = {c1,c2,c3,c4} 
	local r,g,b,a
	for v = 1,4 do
		local src = colors[v]
		local dst = self._colors[v]
		dst[1], dst[2], dst[3], dst[4] = src:unpack_normalized()
	end
	self:_updateVertexBuffer()
end

---Gets all the colors of the 4 vertices
--@return c1 Color of vertex1
--@return c2 Color of vertex2
--@return c3 Color of vertex3
--@return c4 Color of vertex4
function Quad:getColors()
	local colors = {}
	for v = 1,4 do
		local c = self._colors[v]
		colors[#colors+1] = Color.fromNormalizedValues(unpack(c))
	end
	return unpack(colors)
end

