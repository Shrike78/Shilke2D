 --[[---
A TileMap is a displayObject that displays a map built on a set of indices referring to the tiles
of a given TileSet
--]]

TileMap = class(BaseQuad)

---x flip tile flag
TileMap.TILE_X_FLIP = MOAIGridSpace.TILE_X_FLIP
---y flip tile flag
TileMap.TILE_Y_FLIP = MOAIGridSpace.TILE_Y_FLIP
---hide tile flag
TileMap.TILE_HIDE = MOAIGridSpace.TILE_HIDE

---inner mask used to handle tile flags 
local FLAGS_MASK = MOAIGridSpace.TILE_XY_FLIP + MOAIGridSpace.TILE_HIDE


--[[---
Constructor
@param mapData the descriptor of the tilemap
@param mapWidth the width of the map in tiles
@param mapHeight the height of the map in tiles
@param tileset the tileset
@param pivotMode default value is TOP_LEFT or BOTTOM_LEFT according to the coordinate system
in use
--]]
function TileMap:init(mapData, mapWidth, mapHeight, tileset, pivotMode)
	
	local pivotMode = pivotMode and pivotMode or 
		(__USE_SIMULATION_COORDS__ and PivotMode.BOTTOM_LEFT or PivotMode.TOP_LEFT)
		
	BaseQuad.init(self, mapWidth * tileset:getTileWidth(), mapHeight * tileset:getTileHeight(), pivotMode)
	
	self._tileset = tileset
	self._mapWidth , self._mapHeight = mapWidth, mapHeight
	assert(#mapData == mapWidth * mapHeight, "mapData size not consistent with mapWidth and mapHeight")

	--the render table
	self._renderTable = {}
	
	--Following structures are used for handling multi tileset maps.
	--if the tileset in use is a 'single texture atlas' tileset it's a waste of memory, but
	--the behaviour is more general
	
	--take a map of each grid created. Key is the deck for which the grid is created, used as hash
	self._grids = {}
	--take a map of each deck used. Key is the grid binded to the deck, used as hash
	self._decks = {}
	--each non zero entry of the map refers to one of the grid in use.
	self._cells = {}
	
	self:_setMapData(mapData)
end

function TileMap:clone()
	error("it's not possible to clone a TileMap")
	return nil
end

function TileMap:copy(src)
	error("it's not possible to copy a TileMap")
	return false
end

--[[---
returns the grid given a deck. If the grid doesnt' exist it creates it.
@param deck 
@return grid the MOAIGrid that is using the provided deck
--]]
function TileMap:_getGridByDeck(deck)
	if self._grids[deck] then
		return self._grids[deck]
	end
	local prop = MOAIProp.new()
	local grid = MOAIGrid.new()
	grid:setSize ( self._mapWidth, self._mapHeight, self._tileset:getTileWidth(), self._tileset:getTileHeight())
	self._grids[deck] = grid
	self._decks[grid] = deck
	prop:setDeck ( deck )
	prop:setGrid ( grid )
	prop:setParent(self._prop)
	prop:forceUpdate()
	self._renderTable[#self._renderTable+1] = prop
	if #self._renderTable == 1 then
		self._defGrid = grid	
	end
	return grid
end

--[[---
Inner method.
Used to get the correct grid based on grid coordinates
--]]
function TileMap:_getGrid(x,y,bDefault)
	if self._cells[y] then
		if self._cells[y][x] then
			return self._cells[y][x]
		end
	end
	return bDefault and self._defGrid or nil
end


function TileMap:_clearMapData()
	for _,grid in pairs(self._grids) do
		grid:fill(0)
	end
end


--[[---
Private function.
Used to set / replace mapData
@param mapData the mapData to set in the grid
--]]
function TileMap:_setMapData(mapData)
	local tileset = self._tileset
	local mapWidth, mapHeight = self._mapWidth, self._mapHeight
	local id, flags, x, y
	
	for i = 1, mapHeight do
        for j = 1, mapWidth do
			x = j
			y = __USE_SIMULATION_COORDS__ and (mapHeight - i+1) or i
			id, flags = BitOp.splitmask(mapData[(i-1)*mapWidth+j], FLAGS_MASK)
			local deck, id = tileset:_getDeckInfoByGid(id)
			if id > 0 then
				local grid = self:_getGridByDeck(deck)				
				id = id + flags
				grid:setTile(x,y, id)
				if not self._cells[y] then
					self._cells[y] = {}
				end
				self._cells[y][x] = grid
			end
        end
    end
end

--[[---
Used to replace the current mapData.
It's required that the new mapData is 'equivalent' to the previous one, so same number
of tiles and the same size
@param mapData the new mapData used to display the tilemap
--]]
function TileMap:replaceMapData(mapData)
	
	assert(#mapData == self._mapWidth * self._mapHeight, 
		"mapData cannot be replaced becuase its size is not consistent with previous map size")
	
	self:_clearMapData()
	self:_setMapData(mapData)
end

function TileMap:replaceTileSet(tileset)
	if self._tileset:getNumOfTiles() ~= tileset:getNumOfTiles() then
		error("replaceTileSet allow to replace only tilesets of the same size")
	end
	
	local mapData = self:getMapData()
	--self:_resetData(), can be called also by init..
	table.clear(self._renderTable)
	table.clear(self._grids)
	table.clear(self._decks)
	table.clear(self._cells)
	self._tileset = tileset
	self:_setMapData(mapData)
end

--[[---
Returns current mapdata (id and flags)
Recreates mapdata starting from inner grid infos
@return mapdata array[mapWidth*mapHeight] values
--]]
function TileMap:getMapData()
	local mapData = {}
	for i=1,self._mapWidth*self._mapHeight do
		mapData[i] = 0
	end
	for y,v in pairs(self._cells) do
		for x,grid in pairs(v) do
			local id = grid:getTile(x,y)
			local flags = grid:getTileFlags(x,y,FLAGS_MASK)
			id = id - flags
			id = self._tileset:_getGidByDeckInfo(self._decks[grid],id)
			id = id + flags
			if __USE_SIMULATION_COORDS__ then
				mapData[(self._mapHeight - y)*self._mapWidth + x] = id 
			else
				mapData[(y-1)*self._mapWidth + x] = id
			end
		end
	end
	return mapData
end

--[[---
Returns the size of the map 
@return width expressed in number of horizontal tiles
@return height expressed in number of vertical tiles
--]]
function TileMap:getMapSize()
	return self._mapWidth, self._mapHeight
end

--[[---
Returns tile id and flags given map logical coordinates
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@return id tile id at given logical grid coordinates
@return flags tile flags at given logical grid coordinates
--]]
function TileMap:getTileId(x,y)
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	local grid = self:_getGrid(x,y,true)
	local id = grid:getTile(x,y)
	local flags = 0
	if id > 0 then
		flags = grid:getTileFlags(x,y,FLAGS_MASK)
		id = id - flags
		id = self._tileset:_getGidByDeckInfo(self._decks[grid],id)
	end
	return id, flags
end

--[[---
Returns tile given map logical coordinates
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@return Tile tile at given logical grid coordinates
@return flags tile flags at given logical grid coordinates
--]]
function TileMap:getTile(x,y)
	local id, flags = self:getTileId(x,y)
	return self._tileset:getTile(id), flags
end

--[[---
Returns flags given map logical coordinates
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@return flags tile flags
--]]
function TileMap:getTileFlags(x,y)
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	return self:_getGrid(x,y,true):getTileFlags(x,y,FLAGS_MASK)
end

--[[---
Sets a tile data (id and flags) at a given logical position in grid space
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@param id id of the tile at the given position.
@param flags [optional] tile flags to set. 
If provided it replace the current tile flags.
If not provided it doesn't change current flags value.
--]]
function TileMap:setTile(x,y,id,flags)
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	--get current tile grid in order to reset it
	--self:_getGrid(x,y,true):setTile(x,y,0)
	local oldGrid = self:_getGrid(x,y,true)
	local flags = flags or 0
	--set new tile
	local deck, id = self._tileset:_getDeckInfoByGid(id)
	if id > 0 then
		local grid = self:_getGridByDeck(deck)
		if grid ~= oldGrid then
			oldGrid:setTile(x,y,0)
		end
		id = id + flags
		grid:setTile(x,y,id)
		if not self._cells[y] then
			self._cells[y] = {}
		end
		self._cells[y][x] = grid
	else
		oldGrid:setTile(x,y,0)
		if self._cells[y] then
			if self._cells[y][x] then
				self._cells[y][x] = nil
			end
		end
	end			
end

--[[---
Sets tile flags for a specific tile
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@param flags tile flags to set. 
--]]
function TileMap:setTileFlags(x,y,flags)
	assert(flags,"nil value passed as tile flags")
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	--do not set flags for empty tile
	local grid = self:_getGrid(x,y,false)
	if grid then	
		grid:setTileFlags(x,y,flags)
	end
end

--[[---
Clears tile flags for a specific tile
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@param flags tile flags to clear. 
--]]
function TileMap:clearTileFlags(x,y,flags)
	assert(flags,"nil value passed as tile flags")
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	self:_getGrid(x,y,true):clearTileFlags(x,y,flags)
end

--[[---
Toggles tile flags for a specific tile
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@param flags tile flags to toggle. 
--]]
function TileMap:toggleTileFlags(x,y,flags)
	assert(flags,"nil value passed as tile flags")
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	--do not set flags for empty tile
	local grid = self:_getGrid(x,y,false)
	if grid then	
		grid:toggleTileFlags(x,y,flags)
	end
end

--[[---
Tests a tile flag for a specific tile
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@param flag tile flag to test. 
--]]
function TileMap:hasTileFlag(x,y,flag)
	assert(flag,"nil value passed as tile flags")
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	local flags = self:_getGrid(x,y,true):getTileFlags(x,y,FLAGS_MASK)
	return BitOp.testflag(flags,flag)
end

--[[---
Transform a position in targetSpace into a logical position in grid space
@param x x position in targetSpace
@param y y position in targetSpace
@param targetSpace space of the transformation
@return x logical x position in grid space
@return y logical y position in grid space
--]]
function TileMap:positionToGrid(x,y,targetSpace)
	if targetSpace ~= self then 
		x,y = self:globalToLocal(x,y,targetSpace)
	end
	--use a generic grid just to make locToCoord calculation
	x,y = self._defGrid:locToCoord(x,y)
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	return x,y
end

--[[---
Transform a logical position in grid space into a position in targetSpace
The position returned is the centre of the tile
@param x logical x position in grid space
@param y logical y position in grid space
@param targetSpace space of the transformation
@return x position in targetSpace
@return y y position in targetSpace
--]]
function TileMap:gridToPosition(x,y,targetSpace)
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	--tiles are centered
	x = (x - 0.5) * self._tileset:getTileWidth()
	y = (y - 0.5) * self._tileset:getTileHeight()
	if targetSpace ~= self then
		x,y = self:localToGlobal(x,y,targetSpace)
	end
	return x,y
end


--[[---
Alias for gridToPosition
Returns the position of the centre of a tile in targetSpace given logical map coordinates
@param x horizontal logical grid coordinate
@param y vertical logical grid coordinate
@param targetSpace space of the transformation
@return x centre x position in targetSpace coordinates
@return y centre y position in targetSpace coordinates
--]]
function TileMap:getTilePosition(x,y,targetSpace)
	return self:gridToPosition(x,y,targetSpace)
end

--[[---
Returns tile id and flags given a position in targetSpace
@param x x position in targetSpace
@param y y position in targetSpace
@param targetSpace space of the transformation
@return id tile id at given position
--]]
function TileMap:getTileIdByPosition(x,y,targetSpace)
	x,y = self:positionToGrid(x,y,targetSpace)
	return self:getTileId(x,y)
end

--[[---
Returns tile and flags given a position in targetSpace
@param x x position in targetSpace
@param y y position in targetSpace
@param targetSpace space of the transformation
@return Tile tile at given position
@return flags tile flags at given logical grid coordinates
--]]
function TileMap:getTileByPosition(x,y,targetSpace)
	x,y = self:positionToGrid(x,y,targetSpace)
	return self:getTile(x,y)
end

--[[---
Returns flags given a position in targetSpace
@param x x position in targetSpace
@param y y position in targetSpace
@param targetSpace space of the transformation
@return flags tile flags
--]]
function TileMap:getTileFlagsByPosition(x,y,targetSpace)
	x,y = self:positionToGrid(x,y,targetSpace)
	return self:getTileFlags(x,y)
end
