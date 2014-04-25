 --[[---
ITileset defines a common interface for all TileSet class types, giving implementation rules:
 
- A TileSet is a collection of tiles built upon a texture set.
- A TileSet can be made only of tiles of the same size.
- A TileSets wrap MOAIGfxQuadDeck2D structure, binding each texture set source to a single 
quad deck. 
- ITileSet Implementations require a convesion logic between global ids (used by tilemaps)
and a couple of MOAIGfxQuadDeck2D / QuadDeck ids.

The texture set can have multiple configuration. It's usually based on a 
single texture atlas but there're situation (i.e. if the number of tiles is huge 
or it's required to share a subset of tiles between different tilesets) that requires
different atlases. 
--]]
ITileSet = class()

--[[---
A TileSet can have a name and some properties
@param name the name of the tileset
@param properties the named properties of the tileset. Must be in a set of (key, values) form
--]]
function ITileSet:init(name, properties)
	self._name = name
	self._properties = properties
end
	
---convert a global tileset id to a deck + deck id
--@param id the global tileset id
--@return deck the deck that maps te provided id
--@return deckId the id of the tile in returned deck
function ITileSet:_getDeckInfoByGid(id)
    error("method must be overridden")
	return nil, 0
end


---convert a deck + deck id to a global tileset id
--@param deck the deck
--@param deckId the id of the tile in the provided deck
--@return int the global tileset id
function ITileSet:_getGidByDeckInfo(deck, deckId)
    error("method must be overridden")
	return 0
end

---used to check if a deck is valid for a given tileset
--@param deck the deck to be checked
--@return bool if the deck is handled by the tileset
function ITileSet:_hasDeck(deck)
    error("method must be overridden")
	return false
end

---Returns the width of the tiles of the tileset
--@return int width of the tiles
function ITileSet:getTileWidth()
    error("method must be overridden")
	return 0
end

---Returns the height of the tiles of the tileset
--@return int height of the tiles
function ITileSet:getTileHeight()
    error("method must be overridden")
	return 0
end

---Returns the number of tiles of the tileset
--@return int number of tiles
function ITileSet:getNumOfTiles()
    error("method must be overridden")
	return 0
end

---Returns a tile given the tileset id
--@param id tile id
--@return Tile
function ITileSet:getTile(id)
    error("method must be overridden")
	return nil
end

---Sets te name of the tileset
--@param name the name to be set
function ITileSet:setName(name)
	self._name = name
end

---Gets te name of the tileset
--@return name the name currently set
function ITileSet:getName()
	return self._name
end

---Sets a property of the tileset
--@param name the name of the property
--@param value the value of the property
function ITileSet:setProperty(name,value)
	if not self._properties then
		self._properties = {}
	end
	self._properties[name] = value
end

---Gets a property of the tileset
--@param name the name of the property
--@return the value of the property
function ITileSet:getProperty(name)
	return self._properties and self._properties[name] or nil
end


---Sets a property of a tile of the tileset
--@param id the id of the tile
--@param name the name of the property
--@param value the value of the property
function ITileSet:setTileProperty(id, name, value)
	local t = self:getTile(id)
	assert(t,id .. " is not a valid id for this tileset")
	t:setProperty(name,value)
end

---Gets a property of a tile of the tileset
--@param id the id of the tile
--@param name the name of the property
--@return the value of the property
function ITileSet:getTileProperty(id, name)
	local t = self:getTile(id)
	assert(t,id .. " is not a valid id for this tileset")
	t:getProperty(name)
end
