--[[---
A Quad represents a rectangle with a uniform color or a color gradient.

The quad is implemented using a triangle fan mesh made of two triangles, 
with the following vertex order (the same in both coordinate systems):

<pre class="example">
v1---v2
| \   |
|  \  |
|   \ |
v4---v3
</pre>

- Color

Quad implements methods to set/get single vertex color, and helpers to set horizontal 
and vertical color gradients.

By default Quad uses both vertex color and property color, so the resulting color 
is obtained multiplying the two color information (at least using default
quad shader)

Setting __QUAD_VERTEX_COLOR_ONLY__ config directive to true it's possible to force
quads to use only vertex color, leaving property color always to white.

In this configuration Quad overrides DisplayObj color setter/getter: setters work on 
all the vertices, while getters always return the value of the first vertex

--]]

-- basic math function calls
local INV_255 = 1/255

-- helper table for vertex buffer creation
local _vcoords = {{0,0},{0,0},{0,0},{0,0}}

-- default quad shader, created first time a quad is created
local _quad_shader = nil

local function getDefaultQuadShader()
	-- the default quad shader is created the first time a quad is created. 
	if not _quad_shader then
		_quad_shader = MOAIShader.new()
		local vsh = IO.getFile("/Shilke2D/Resources/quad.vsh")
		local fsh = IO.getFile("/Shilke2D/Resources/quad.fsh")
		_quad_shader:reserveUniforms(2)
		_quad_shader:declareUniform(1, 'transform', MOAIShader.UNIFORM_WORLD_VIEW_PROJ )
		_quad_shader:declareUniform(2, 'ucolor', MOAIShader.UNIFORM_PEN_COLOR )
		_quad_shader:setVertexAttribute( 1, 'position' )
		_quad_shader:setVertexAttribute( 2, 'color' )
		_quad_shader:load( vsh, fsh )
	end
	return _quad_shader
end


Quad = class(BaseQuad)

---
-- Constructor.
-- @param width quad width
-- @param height quad height
-- @param pivotMode optional, defaul value is CENTER
function Quad:init(width,height,pivotMode)
	BaseQuad.init(self,width,height,pivotMode)
	-- if quad completely overrides base color property,
	-- use displayobj _color as first of the 4 vertex colors
	-- to reduce memory allocation
	if __QUAD_VERTEX_COLOR_ONLY__ then
		self._vcolors = {
			self._color,
			{1,1,1,1},
			{1,1,1,1},
			{1,1,1,1}
		}
	else
		self._vcolors = {
			{1,1,1,1},
			{1,1,1,1},
			{1,1,1,1},
			{1,1,1,1}
		}
	end
	self:_createMesh()
	self:_updateVertexBuffer()
	self:setShader(getDefaultQuadShader())
end


---
-- release any used memory
function Quad:dispose()
	BaseQuad.dispose(self)
	self._mesh = nil
	self._vbo:release()
	self._vbo = nil
	self._vertexFormat = nil
end

---
-- Set the size of the quad
-- @param width quad width
-- @param height quad height
function Quad:setSize(width,height)
	BaseQuad.setSize(self,width,height)
	self:_updateVertexBuffer()
end

---
-- override default quad shader
-- if no shader is provided it resets to default quad shader
-- @tparam[opt=nil] MOAIShader shader
function Quad:setShader(shader)
	if shader then
		self._prop:setShader(shader)
	else
		self._prop:setShader(getDefaultQuadShader())
	end
end


---
-- Inner method. It creates the quad mesh that will be displayed
function Quad:_createMesh()
	self._vertexFormat = MOAIVertexFormat.new()
	self._vertexFormat:declareCoord( 1, MOAIVertexFormat.GL_FLOAT, 2 )
	self._vertexFormat:declareColor( 2, MOAIVertexFormat.GL_UNSIGNED_BYTE )
	
	self._vbo = MOAIVertexBuffer.new()
	self._vbo:setFormat( self._vertexFormat )
	self._vbo:reserveVerts( 4 )
	
	self._mesh = MOAIMesh.new()
	self._mesh:setVertexBuffer( self._vbo )
	self._mesh:setPrimType( MOAIMesh.GL_TRIANGLE_FAN )
	
	self._prop:setDeck(self._mesh)
end


---
-- Inner methods. 
-- Called everytime geometric or color information are changed, 
-- to update mesh vertices infos.
function Quad:_updateVertexBuffer()
	-- create with same vertex orders for both coordinate systems
	if __USE_SIMULATION_COORDS__ then
		--_vcoords[1][1] = 0
		_vcoords[1][2] = self._height
		_vcoords[2][1] = self._width
		_vcoords[2][2] = self._height
		_vcoords[3][1] = self._width
		_vcoords[3][2] = 0
		--_vcoords[4][1] = 0
		_vcoords[4][2] = 0
	else
		--_vcoords[1][1] = 0
		_vcoords[1][2] = 0
		_vcoords[2][1] = self._width
		_vcoords[2][2] = 0
		_vcoords[3][1] = self._width
		_vcoords[3][2] = self._height
		--_vcoords[4][1] = 0
		_vcoords[4][2] = self._height
	end

	self._vbo:reset()
	
	local c,a
	local pma = self:hasPremultipliedAlpha()
	for i=1,4 do
		--  write vertex position
		self._vbo:writeFloat ( _vcoords[i][1], _vcoords[i][2] )              
		--  write RGBA value
		c = self._vcolors[i]
		if pma then
			a = c[4]
			self._vbo:writeColor32(c[1]*a, c[2]*a, c[3]*a, a)
		else
			self._vbo:writeColor32(c[1], c[2], c[3], c[4])
		end
	end
    
	self._vbo:bless ()	

end

---
-- Set alpha value for a single vertex
-- @param v index of the vertex [1,4]
-- @param a alpha value [0,255]
function Quad:setVertexAlpha(v,a) 
	self._vcolors[v][4] = a * INV_255
	self:_updateVertexBuffer()
end

---
-- Returns alpha value of a single vertex
-- @param v index of the vertex [1,4]
-- @return alpha value [0,255]
function Quad:getVertexAlpha(v)
   return self._vcolors[v][4]*255
end


---
-- Set vertex color.
-- @tparam int v vertex index (1,4)
-- @param r (0,255) value or Color object or hex string or int32 color
-- @param g (0,255) value or nil
-- @param b (0,255) value or nil
-- @param a[opt=nil] (0,255) value or nil
function Quad:setVertexColor(v,r,g,b,a) 
	local c = self._vcolors[v]
	c[1], c[2], c[3], c[4] = Color._toNormalizedRGBA(r,g,b,a)
	self:_updateVertexBuffer()
end

---
-- Returns vertext color of a single vertex
-- @param v index of the vertex [1,4]
-- @return Color
function Quad:getVertexColor(v)
  return Color.fromNormalizedValues(unpack(self._vcolors[v]))
end

---
-- Sets all the colors of the 4 vertices
-- @param c1 Color of vertex1
-- @param c2 Color of vertex2
-- @param c3 Color of vertex3
-- @param c4 Color of vertex4
function Quad:setColors(c1,c2,c3,c4)
	local colors = {c1,c2,c3,c4} 
	local r,g,b,a
	for v = 1,4 do
		local src = colors[v]
		-- handle colors provided as named colors (or hex strings)
		if class_type(src) ~= Color then
			src = Color(src)
		end
		local dst = self._vcolors[v]
		dst[1], dst[2], dst[3], dst[4] = src:unpack_normalized()
	end
	self:_updateVertexBuffer()
end

---
-- Gets all the colors of the 4 vertices
-- @return c1 Color of vertex1
-- @return c2 Color of vertex2
-- @return c3 Color of vertex3
-- @return c4 Color of vertex4
function Quad:getColors()
	local colors = {}
	for v = 1,4 do
		local c = self._vcolors[v]
		colors[#colors+1] = Color.fromNormalizedValues(unpack(c))
	end
	return unpack(colors)
end

---
-- Sets an horizontal gradient
-- @tparam Color c1 left color
-- @tparam Color c2 right color
function Quad:setHorizontalGradient(c1,c2)
	self:setColors(c1,c2,c2,c1)
end

---
-- Sets a vertical gradient
-- @tparam Color c1 top color
-- @tparam Color c2 bottom color
function Quad:setVerticalGradient(c1,c2)
	self:setColors(c1,c1,c2,c2)
end


-- the quad vertex color only (default disabled) allows to 
-- override normal set/get color logic using only vertex
-- color (and leaving always prop color white)
if __QUAD_VERTEX_COLOR_ONLY__ then

	--
	-- overrides DisplayObj method redirecting on _updateVertexBuffer
	-- that already does the same thing for quads
	-- @function Quad:_updateColor
	Quad._updateColor = Quad._updateVertexBuffer

	-- closure helper for color channel setters
	local function _setColorChannel(channel)
		return function(self, v)
			local v = v * INV_255
			for i = 1,4 do
				self._vcolors[i][channel] = v
			end
			self:_updateVertexBuffer()
		end
	end
	
	-- closure helper for color channel getters
	-- NB: to optimize memory self._vcolors[1] reuses self._color, 
	-- so the color getters could be the same of DisplayObj,
	-- but in future the logic could change..
	local function _getColorChannel(channel)
		return function(self)
			return self._vcolors[1][channel] * 255
		end
	end
			
	--
	-- Set red channel for all vertices
	-- @function Quad:setRed
	-- @tparam int r red [0,255]
	Quad.setRed = _setColorChannel(1)

	--
	-- Get red color channel
	-- @function Quad:getRed
	-- @treturn int red [0,255]
	Quad.getRed = _getColorChannel(1)
	
	--
	-- Set green channel for all vertices
	-- @function Quad:setGreen
	-- @tparam int g green [0,255]
	Quad.setGreen = _setColorChannel(2)

	--
	-- Get green color channel
	-- @function Quad:getGreen
	-- @treturn int green [0,255]
	Quad.getGreen = _getColorChannel(2)
	
	--
	-- Set blue channel for all vertices
	-- @function Quad:setBlue
	-- @tparam int b blue [0,255]
	Quad.setBlue = _setColorChannel(3)

	--
	-- Get blue color channel
	-- @function Quad:getBlue
	-- @treturn int blue [0,255]
	Quad.getBlue = _getColorChannel(3)
	
	--
	-- Set alpha value for all vertices
	-- @function Quad:setAlpha
	-- @tparam int a alpha value [0,255]
	Quad.setAlpha = _setColorChannel(4)
	
	--
	-- Return alpha value of the object
	-- @function Quad:getAlpha
	-- @treturn int alpha [0,255]
	Quad.getAlpha = _getColorChannel(4)


	--
	-- Set obj color.
	-- @param r (0,255) value or Color object or hex string or int32 color
	-- @param g (0,255) value or nil
	-- @param b (0,255) value or nil
	-- @param a[opt=nil] (0,255) value or nil
	function Quad:setColor(r,g,b,a)
		local r,g,b,a = Color._toNormalizedRGBA(r,g,b,a)	
		for i = 1,4 do
			self._vcolors[i][1] = r
			self._vcolors[i][2] = g
			self._vcolors[i][3] = b
			self._vcolors[i][4] = a
		end
		self:_updateVertexBuffer()
	end
	
	--
	-- Returns the color of the first vertex. 
	-- @return Color
	function Quad:getColor()
		return Color.fromNormalizedValues(unpack(self._vcolors[1]))
	end

end