--[[---
A Quad represents a rectangle with a uniform color or a color gradient.

It's possible to set one color per vertex. The colors will smoothly 
fade into each other over the area of the quad. 

The quad is implemented using a triangle fan mesh made of two triangles, 
with the following vertex order (the same in both coordinate systems):

v1---v2
| \   |
|  \  |
|   \ |
v4---v3

--]]

--basic math function calls
local INV_255 = 1/255

--default quad shader, created first time a quad is created
local _quad_shader = nil

Quad = class(BaseQuad)

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


---release any used memory
function Quad:dispose()
	BaseQuad.dispose(self)
	self._mesh = nil
	self._vbo:release()
	self._vbo = nil
	self._vertexFormat = nil
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
		
	self._vertexFormat = MOAIVertexFormat.new ()
	self._vertexFormat:declareCoord ( 1, MOAIVertexFormat.GL_FLOAT, 2 )
	self._vertexFormat:declareColor ( 2, MOAIVertexFormat.GL_UNSIGNED_BYTE )

	self._vbo = MOAIVertexBuffer.new ()
	self._vbo:setFormat ( self._vertexFormat )
	self._vbo:reserveVerts ( 4 )

	self._mesh = MOAIMesh.new ()
	self._mesh:setVertexBuffer ( self._vbo )
	self._mesh:setPrimType ( MOAIMesh.GL_TRIANGLE_FAN )
	
	--shader creation is done first time a quad is created. 
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
	
	local vcoords 
	--create with same vertex orders for both coordinate system
	if __USE_SIMULATION_COORDS__ then
		vcoords = {{ 0, self._height },
					{ self._width, self._height },
					{ self._width, 0 },
					{ 0, 0 }}
	else
		vcoords = {{ 0, 0 },
					{ self._width, 0 },
					{ self._width, self._height },
					{ 0, self._height }}
	end

	self._vbo:reset()
	
	local c,a
	for i=1, #vcoords do
		-- write vertex position
		self._vbo:writeFloat ( vcoords[i][1], vcoords[i][2] )              
		-- write RGBA value
		c = self._colors[i]
		if self._premultipliedAlpha then
			a = c[4]
			self._vbo:writeColor32(c[1]*a, c[2]*a, c[3]*a, a)
		else
			self._vbo:writeColor32(c[1], c[2], c[3], c[4])
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
@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
--]]
function Quad:setColor(r,g,b,a)
	local r,g,b,a = Color._toNormalizedRGBA(r,g,b,a)	
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
@tparam int v vertex index (1,4)
@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@param a[opt=nil] (0,255) value or nil
--]]
function Quad:setVertexColor(v,r,g,b,a) 
	local c = self._colors[v]
	c[1], c[2], c[3], c[4] = Color._toNormalizedRGBA(r,g,b,a)
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
		--handle colors provided as named colors (os hex strings)
		if class_type(src) ~= Color then
			src = Color(src)
		end
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

--[[---
Sets an horizontal gradient
@tparam Color c1 left color
@tparam Color c2 right color
--]]
function Quad:setHorizontalGradient(c1, c2)
	self:setColors(c1,c2,c2,c1)
end

--[[---
Sets a vertical gradient
@tparam Color c1 top color
@tparam Color c2 bottom color
--]]
function Quad:setVerticalGradient(c1,c2)
	self:setColors(c1,c1,c2,c2)
end
