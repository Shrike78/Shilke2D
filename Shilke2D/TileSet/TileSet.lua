 --[[---
TileSet is the most common type of tileset that can be used in Shilke2D.

- It wraps exactly one single texture atlas made on a single texture. 
- It allows to replace the texture atlas if the size and the number of the textures 
is the same

--]]

TileSet = class(nil, ITileSet)


--[[---
Constructor
@param atlas the texture atlas containing the textures on which the tileset is built. 
@param name the name of the tileset (optional) 
@param properties a collection of properties of the tileset (optional)
@param tilesProperties a collection of collection of properties of the tiles (optional) 
--]]
function TileSet:init(atlas, name, properties, tilesProperties)
	ITileSet.init(self, name, properties)
	
	local textures = atlas:getTextures()
	
	self.tilewidth = textures[1].width
	self.tileheight = textures[1].height
	local textureData = textures[1].textureData
	
	local gfxQuadDeck = MOAIGfxQuadDeck2D.new()
	self._gfxQuadDeck = gfxQuadDeck
	gfxQuadDeck:setTexture( textureData )
	gfxQuadDeck:reserve( #textures )
	
	self.tiles = {}
	local tilesProperties = tilesProperties and tilesProperties or {}
	local tile, r = nil, nil
	
	for i,texture in ipairs(textures) do
		assert(texture.width == self.tilewidth and texture.height == self.tileheight, 
			"all the tiles must have the same size")
		assert(texture.textureData == textureData, "all the tile must have the same textureData")
		tile = Tile(self, i, texture, tilesProperties[i])
		texture:_fillQuadDeckUV(gfxQuadDeck, i)
		self.tiles[#self.tiles+1] = tile
	end
end


---Replace the tileset texture set with a new texture set defined by the atlas
--@param atlas the atlas with the new texture set
function TileSet:replaceAtlas(atlas)
	
	local textures = atlas:getTextures()
	
	assert(#textures == #self.tiles, "replace of atlas cannot be done if number of textures is not the same")
	
	assert(self.tilewidth == textures[1].width and self.tileheight == textures[1].height,
		"replace of atlas cannot be done if texture size is not the same")
	
	local textureData = textures[1].textureData
	--update gfxQuadDeck and tiles
	local gfxQuadDeck = self._gfxQuadDeck 
	gfxQuadDeck:setTexture ( textureData )
	for i,texture in ipairs(textures) do
		assert(texture.width == self.tilewidth and texture.height == self.tileheight, 
			"all the tiles must have the same size")
		assert(texture.textureData == textureData, "all the tile must have the same textureData")
		self.tiles[i]:_replaceTexture(texture)
		texture:_fillQuadDeckUV(gfxQuadDeck, i)
	end

end	


---convert a global tileset id to a deck + deck id
--@param id the global tileset id
--@return deck the deck that maps the provided id
--@return deckId the id of the tile in returned deck
function TileSet:_getDeckInfoByGid(id)
	return self._gfxQuadDeck,id
end

---convert a deck + deck id to a global tileset id
--@param deck the deck
--@param deckId the id of the tile in the provided deck
--@return int the global tileset id
function TileSet:_getGidByDeckInfo(deck, deckId)
	assert(deck == self._gfxQuadDeck)
	return deckId
end

---used to check if a deck is valid for a given tileset
--@param deck the deck to be checked
--@return bool if the deck is handled by the tileset
function TileSet:_hasDeck(deck)
	return deck == self._gfxQuadDeck
end

---Returns the width of the tiles of the tileset
--@return int width of the tiles
function TileSet:getTileWidth()
	return self.tilewidth
end

---Returns the height of the tiles of the tileset
--@return int height of the tiles
function TileSet:getTileHeight()
	return self.tileheight
end

---Returns the number of tiles of the tileset
--@return int number of tiles
function TileSet:getNumOfTiles()
	return #self.tiles
end

---Returns a tile given the global id
--@param id tile id
--@return Tile
function TileSet:getTile(id)
	return self.tiles[id]
end




