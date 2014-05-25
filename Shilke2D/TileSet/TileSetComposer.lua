--[[---
TileSetComposer is used when multiple atlas are required. 

Following the composite pattern, a TileSetComposer implements ITileSet itself 
and is composed by multiple ITileSet component. 

The resulting tileset is the union of all the tiles of the single tilesets, with 
tile ids remapped based on add order. 

Each new ITileSet tile indexing has an offset equals to the number of the tiles 
handled at adding time.
--]]

TileSetComposer = class(nil, ITileSet)

--[[---
Constructor
@param name the name of the tileset (optional) 
@param properties a collection of properties of the tileset (optional)
--]]
function TileSetComposer:init(name, properties)
	ITileSet.init(self, name, properties)
	self._tilesets = {}
end

--[[---
Extends the logical tileset virtually adding all the tiles of the given tileset to the current
tile set
@param tileset the new tileset to add
@return gid the base gid of the newly added tileset. It represents the offset that will be used to 
address the tiles of the given tileset in the logical extended tileset.
--]]
function TileSetComposer:addTileSet(tileset)
	if #self._tilesets > 0 then
		--The assert is done just as a check only on the first tile.
		--The same assertion should be done for all the tiles!
		assert(self:getTileWidth() == tileset:getTileWidth() and self:getTileHeight() == tileset:getTileHeight(),
			"atlas cannot be add if texture size is not the same of already added textures")
	end
	local gid = self:getNumOfTiles() + 1
	table.insert(self._tilesets, 1, {gid, tileset})
	return gid
end


---Returns the width of the tiles of the tileset
--@return int width of the tiles
function TileSetComposer:getTileWidth()
	if #self._tilesets == 0 then
		return 0
	end
	return self._tilesets[1][2]:getTileWidth()
end

---Returns the height of the tiles of the tileset
--@return int height of the tiles
function TileSetComposer:getTileHeight()
	if #self._tilesets == 0 then
		return 0
	end
	return self._tilesets[1][2]:getTileHeight()
end


--[[---
Returns the proper inner tileset given a gid
@param gid the gid to which the searched tileset belong
@return tileset the searched tileset
@return id the local id (conversion from composite tileset id to component tile id)
--]]
function TileSetComposer:getTileSetByGid(gid)
	for _,v in ipairs(self._tilesets) do
		if gid >= v[1] then
			return v[2], (gid-v[1]+1)
		end
	end
	return nil, 0
end


---returns the deck/deck id of the component tileset
--@param gid the global tileset id
--@return deck the deck that maps the provided id
--@return deckId the id of the tile in returned deck
function TileSetComposer:_getDeckInfoByGid(gid)
	for _,v in ipairs(self._tilesets) do
		if gid >= v[1] then
			return v[2]:_getDeckInfoByGid(gid-v[1]+1)
		end
	end
	return nil,0
end


---Search for the component tileset to which the provided deck belongs and 
--then make it returns the gid based on the provided id
--@param deck the deck
--@param id the id of the tile in the provided deck
--@return int the global tileset id
function TileSetComposer:_getGidByDeckInfo(deck,id)
	for _,v in ipairs(self._tilesets) do
		if v[2]:_hasDeck(deck) then
			return v[2]:_getGidByDeckInfo(deck, id + v[1] -1)
		end
	end
end

---used to check if a deck is valid for a given tileset
--@param deck the deck to be checked
--@return bool if the deck is handled by the tileset
function TileSetComposer:_hasDeck(deck)
	for _,v in ipairs(self._tilesets) do
		if v[2]:_hasDeck(deck) then
			return true
		end
	end
	return false
end

---Returns the number of tiles of the tileset
--@return int number of tiles
function TileSetComposer:getNumOfTiles()
	local numOfTiles = 0
	for _,v in pairs(self._tilesets) do
		numOfTiles = numOfTiles + v[2]:getNumOfTiles()
	end
	return numOfTiles
end

---Returns a tile given the global id
--@param gid the global id of the tile
--@return Tile
function TileSetComposer:getTile(gid)
	for _,v in ipairs(self._tilesets) do
		if gid >= v[1] then
			return v[2]:getTile(gid-v[1]+1)
		end
	end
	return nil
end
