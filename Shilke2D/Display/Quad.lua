-- Quad

--[[ 

A Quad represents a rectangle with a uniform color or a color gradient.
It's possible to set one color per vertex. The colors will smoothly 
fade into each other over the area of the quad. To display a simple 
linear color gradient, assign one color to vertices 1 and 2 and 
another color to vertices 3 and 4. 

The indices of the vertices are arranged like this:

4 - 3
| / |
1 - 2
    
--]]

Quad = class(FixedSizeObject)

function Quad:init(width,height,pivotMode)
	FixedSizeObject.init(self,width,height,pivotMode)
	
	self._colors = {{1,1,1,1},
					{1,1,1,1},
					{1,1,1,1},
					{1,1,1,1}}
	
	self:_createMesh()
	self:_updateVertexBuffer()
	
	self._prop:setDeck(self._mesh)
end

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

function Quad:_updateVertexBuffer()
	
	local vcoords = {{ -self._width/2, -self._height/2 },
					{ self._width/2, -self._height/2 },
					{ self._width/2, self._height/2 },
					{ -self._width/2, self._height/2 }}
	
	self._vbo:reset()
	
	for i=1, #vcoords do
		-- write vertex position
		self._vbo:writeFloat ( vcoords[i][1], vcoords[i][2] )              
		-- write RGBA value
		self._vbo:writeColor32 ( self._colors[i][1], self._colors[i][2], 
			self._colors[i][3], self._colors[i][4] * self._multiplyAlpha)  
	end
    
	self._vbo:bless ()	
end

function Quad:setSize(width,height)
	FixedSizeObject.setSize(self,width,height)
	self:_updateVertexBuffer()
end

-- public Setter and Getter

function Quad:_setMultiplyAlpha(a)
    self._multiplyAlpha = a / 255
    self:_updateVertexBuffer()
end

function Quad:_getMultipliedAlpha()
   return self._multiplyAlpha * (self._colors[1][4] * 255)
end

function Quad:setAlpha(a)
    for i = 1,4 do
        self._colors[i][4] = a/255
    end
    self:_updateVertexBuffer()
end

function Quad:getAlpha()
   return self._colors[1][4]*255
end

function Quad:setVertexAlpha(v,a) 
    self._colors[v][4] = a/255
	self:_updateVertexBuffer()
end

function Quad:getVertexAlpha(v)
   return self._colors[v][4]*255
end

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


function Quad:getColor()
  local r,g,b,a = self._colors[1][1],self._colors[1][2],self._colors[1][3],self._colors[1][4]
  return Color(r*255,g*255,b*255,a*255)
end


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

function Quad:getVertexColor(v)
  local r,g,b,a = self._colors[v][1],self._colors[v][2],self._colors[v][3],self._colors[v][4]
  return Color(r*255,g*255,b*255,a*255)
end

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


