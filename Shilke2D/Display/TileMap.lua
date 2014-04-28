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
	--if a grid has been already created for this deck just return it
	if self._grids[deck] then
		return self._grids[deck]
	end
	--create a new grid and a new moai prop that render the grid
	local prop = MOAIProp.new()
	local grid = MOAIGrid.new()
	--configure the grid with the required size (map w,h and tiles w,h)
	grid:setSize ( self._mapWidth, self._mapHeight, self._tileset:getTileWidth(), self._tileset:getTileHeight())
	--initialize double linked references of grid2deck / deck2grid
	self._grids[deck] = grid
	self._decks[grid] = deck
	--configure the new prop setting the grid and the deck
	prop:setDeck ( deck )
	prop:setGrid ( grid )
	--set the main prop as parent for the newly created prop and force an update in order to 
	--update all geometry and color links
	prop:setParent(self._prop)
	prop:forceUpdate()
	--add the new prop to the render table
	self._renderTable[#self._renderTable+1] = prop
	--the first grid created is also used as default grid (that is the grid used to 
	--address position checks)
	if #self._renderTable == 1 then
		self._defGrid = grid	
	end
	return grid
end

--[[---
Inner method. 
Used to get the correct grid based on grid coordinates. 
It returns a grid if a tile is set at x,y, else nil.
@param x the x grid coordinate
@param y the y grid coordinate
--]]
function TileMap:_getGrid(x,y)
	if self._cells[y] then
		return self._cells[y][x]
	end
	return nil
end

---Set tile 0 for all the entries of all the inner moai grids
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
        for x = 1, mapWidth do
			y = __USE_SIMULATION_COORDS__ and (mapHeight - i+1) or i
			--uses FLAGS_MASK to split the provided id into a id, flags couple of values
			id, flags = BitOp.splitmask(mapData[(i-1)*mapWidth+x], FLAGS_MASK)
			--if a valid tile is set in that position
			if id > 0 then
				--use the global id to retrieve the deck, deck id infos from tileset
				local deck, id = tileset:_getDeckInfoByGid(id)
				--get (or create) the grid using the deck
				local grid = self:_getGridByDeck(deck)	
				--add flags to the tileset local id
				id = id + flags
				--set the id+flags in the x,y position of the grid
				grid:setTile(x,y,id)
				--set cells[y][x] = grid 
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
@param mapData the new mapData used to display the tilemap
--]]
function TileMap:replaceMapData(mapData)
	
	assert(#mapData == self._mapWidth * self._mapHeight, 
		"mapData cannot be replaced becuase its size is not consistent with previous map size")
	
	self:_clearMapData()
	self:_setMapData(mapData)
end

---Replace the current tileset leaving mapdata unchanged. It's required that the new tileset
--is equivalent to the previous one, that means same number of tiles
--@param tileset the new tileset
function TileMap:replaceTileSet(tileset)
	if self._tileset:getNumOfTiles() ~= tileset:getNumOfTiles() then
		error("replaceTileSet allow to replace only tilesets of the same size")
	end
	
	--get current mapData (included flags)
	local mapData = self:getMapData()
	--clears all the inner tables
	table.clear(self._renderTable)
	table.clear(self._grids)
	table.clear(self._decks)
	table.clear(self._cells)
	--set new tileset
	self._tileset = tileset
	--create new mapdata
	self:_setMapData(mapData)
end

--[[---
Returns current mapdata (id and flags)
Recreates mapdata starting from inner grid infos
@return mapdata array[mapWidth*mapHeight] values
--]]
function TileMap:getMapData()
	--create a new array and fill it with 0 for the size of mapdata
	local mapData = {}
	for i=1,self._mapWidth*self._mapHeight do
		mapData[i] = 0
	end
	
	local id, flags
	--for each entry of _cells retrieve the global id+flags and set it to correct mapdata position
	--_cells is filled as a sparse list of rows where each row is a sparse list of column values
	for y,v in pairs(self._cells) do
		for x,grid in pairs(v) do
			--retrieve local grid id+flags
			id = grid:getTile(x,y)
			--split it
			id, flags = BitOp.splitmask(id, FLAGS_MASK)
			--retrieve global id 
			id = self._tileset:_getGidByDeckInfo(self._decks[grid],id)
			--apply back flags
			id = id + flags
			--convert y based on simulation coords.
			local yh = __USE_SIMULATION_COORDS__ and (self._mapHeight-y) or (y-1)
			--set id to mapdata
			mapData[ yh * self._mapWidth + x] = id 
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
	--convert y based on simulation coords.
	y = __USE_SIMULATION_COORDS__ and (self._mapHeight-y+1) or y
	local id = 0
	local flags = 0
	local grid = self:_getGrid(x,y)
	--if not tile is set at x,y, grid is nil
	if grid then
		id = grid:getTile(x,y)
		id, flags = BitOp.splitmask(id,FLAGS_MASK)
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
	local grid = self:_getGrid(x,y)
	if grid then
		return grid:getTileFlags(x,y,FLAGS_MASK)
	end
	return 0
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
	local oldGrid = self:_getGrid(x,y)
	--if a valid is is set
	if id > 0 then
		--check for flags
		local flags = flags or 0
		--get deck, deck id by global tile id
		local deck, id = self._tileset:_getDeckInfoByGid(id)
		--get grid by deck
		local grid = self:_getGridByDeck(deck)
		--if the previous grid had a value and is different from 
		--current grid, reset it
		if oldGrid and grid ~= oldGrid then
			oldGrid:setTile(x,y,0)
		end
		--set id+flags with one call
		id = id + flags
		grid:setTile(x,y,id)
		--update _cells[y][x]
		if not self._cells[y] then
			self._cells[y] = {}
		end
		self._cells[y][x] = grid
	else
		--if oldGrid was set, reset it
		if oldGrid then
			oldGrid:setTile(x,y,0)
		end
		--remove _cells[y][x] entry
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
	local grid = self:_getGrid(x,y)
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
	local grid = self:_getGrid(x,y)
	if grid then
		grid:clearTileFlags(x,y,flags)
	end
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
	local grid = self:_getGrid(x,y)
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
	local grid = self:_getGrid(x,y)
	if not grid then
		return false
	end
	local flags = grid:getTileFlags(x,y,FLAGS_MASK)
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
