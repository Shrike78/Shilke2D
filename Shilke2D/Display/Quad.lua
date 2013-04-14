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

Quad = class(BaseQuad)

---Quad are drawn using a pixel shader so it's necessary to have
--it enabled to inherits ancestors color values
Quad._defaultUseMultiplyColor = true

--[[---
Constructor.
@param width quad width
@param height quad height
@param pivotMode optional, defaul value is CENTER
--]]
function Quad:init(width,height,pivotMode)
	BaseQuad.init(self,width,height,pivotMode)
	
	self._colors = {{1,1,1,1},
					{1,1,1,1},
					{1,1,1,1},
					{1,1,1,1}}
	
	self:_createMesh()
	self:_updateVertexBuffer()
	
	self._prop:setDeck(self._mesh)
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
	
	local shader = MOAIShader.new ()
    local vsh = IO.getFile("/Shilke2D/Resources/quad.vsh")
    local fsh = IO.getFile("/Shilke2D/Resources/quad.fsh")
    
    shader:reserveUniforms(2)
    shader:declareUniform(1, 'transform', MOAIShader.UNIFORM_WORLD_VIEW_PROJ )
    shader:declareUniform(2, 'ucolor', MOAIShader.UNIFORM_PEN_COLOR )
    
    shader:setVertexAttribute ( 1, 'position' )
    shader:setVertexAttribute ( 2, 'color' )
    shader:load ( vsh, fsh )
	
	self._mesh:setShader(shader)
end

---Inner methods. 
--Called everytime geometric or color information are changed, 
--to update mesh vertices infos.
function Quad:_updateVertexBuffer()
	
	local vcoords = {{ -self._width/2, -self._height/2 },
					{ self._width/2, -self._height/2 },
					{ self._width/2, self._height/2 },
					{ -self._width/2, self._height/2 }}
	
	self._vbo:reset()
	
	local r,g,b,a = Color.int2rgba(self._multiplyColor)
	r = r/255
	g = g/255
	b = b/255
	a = a/255
	
	for i=1, #vcoords do
		-- write vertex position
		self._vbo:writeFloat ( vcoords[i][1], vcoords[i][2] )              
		-- write RGBA value
		self._vbo:writeColor32 ( self._colors[i][1] * r, self._colors[i][2] * g, 
			self._colors[i][3] * b, self._colors[i][4] * a)  
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

---Override base method. It calls _updateVertexBuffer
--@param c an int obtained by Color.rgba2int([0,255],[0,255],[0,255],[0,255])
function Quad:_setMultiplyColor(c)
    self._multiplyColor = c
    self:_updateVertexBuffer()
end

---Returns the multiplied alpha value as applied to the first vertex. 
--If alpha values is different per vertices the return value has no real meaning
--@return int obtained by Color.rgba2int([0,255],[0,255],[0,255],[0,255])
function Quad:_getMultipliedColor()
	local r,g,b,a = Color.int2rgba(self._multiplyColor)
	r = r * self._colors[1][1]  
	g = g * self._colors[1][2]  
	b = b * self._colors[1][3]  
	a = a * self._colors[1][4]
    return Color.rgba2int(r,g,b,a)
end


---Override base method. It calls _updateVertexBuffer
--@param a alpha value [0,255]
function Quad:setAlpha(a)
    for i = 1,4 do
        self._colors[i][4] = a/255
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
    self._colors[v][4] = a/255
	self:_updateVertexBuffer()
end

---Returns alpha value of a single vertex
--@param v index of the vertex [1,4]
--@return alpha value [0,255]
function Quad:getVertexAlpha(v)
   return self._colors[v][4]*255
end

--[[---
Override base method. It calls _updateVertexBuffer
The following calls are valid:
- setColor(r,g,b)
- setColor(r,g,b,a)
- setColor(color)
@param r red value [0,255] or a Color
@param g green value [0,255] or nil
@param b blue value [0,255] or nil
@param a alpha value [0,255] or nil
--]]
function Quad:setColor(r,g,b,a)
	local _r,_g,_b,_a
	if type(r) == 'number' then
		_r = r/255
		_g = g/255
		_b = b/255
		_a = a and a / 255 or self._colors[1][4]
	else
		_r, _g, _b, _a = r:unpack_normalized()
	end
	for i = 1,4 do
		self._colors[i][1] = _r
		self._colors[i][2] = _g
		self._colors[i][3] = _b
		self._colors[i][4] = _a
	end
	self:_updateVertexBuffer()
end

---Returns the color of the first vertex. 
--If color value is per vertices the return value has no real meaning
--@return Color
function Quad:getColor()
  local r,g,b,a = self._colors[1][1],self._colors[1][2],self._colors[1][3],self._colors[1][4]
  return Color(r*255,g*255,b*255,a*255)
end

--[[---
Set color of a single vertex
The following calls are valid:
- setVertexColor(v,r,g,b)
- setVertexColor(v,r,g,b,a)
- setVertexColor(v,color)
@param v index of the vertex [1,4]
@param r red value [0,255] or a Color
@param g green value [0,255] or nil
@param b blue value [0,255] or nil
@param a alpha value [0,255] or nil
--]]
function Quad:setVertexColor(v,r,g,b,a) 
	local col = self._colors[v]
	
	if type(r) == 'number' then
		col[1] = r/255
		col[2] = g/255
		col[3] = b/255
		col[4] = a and a/255 or col[4]
	else
		col[1], col[2], col[3], col[4] = r:unpack_normalized()
	end
    
	self:_updateVertexBuffer()
end

---Returns vertext color of a single vertex
--@param v index of the vertex [1,4]
--@return Color
function Quad:getVertexColor(v)
  local r,g,b,a = self._colors[v][1],self._colors[v][2],self._colors[v][3],self._colors[v][4]
  return Color(r*255,g*255,b*255,a*255)
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


