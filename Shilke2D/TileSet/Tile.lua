 --[[---
Tile is the base object for tilemap management.
A tile is always part of a tileset, a collection of tiles, and
it's nothing more than a wrapper of a texture with some more 
properties.

It's possible to create custom tiles extending Tile class and registering 
new classes using TileManager. 
--]]

Tile = class()

--[[---
Constructor
@param tileset the tileset to which the tile belongs to
@param id the id of the tile in the tileset
@param texture the texture wrapped by the tile
@param properties an (optional) collection of properties of the tile
--]]
function Tile:init(tileset, id, texture, properties)
	self.tileset = tileset
	self.id = id
	self.texture = texture
	self.properties = properties
end

--[[---
Internal function.
Replaces inner texture.
Called from TileSet for atlas replacement
@param texture new texture for replacement
--]]
function Tile:_replaceTexture(texture)
	self.texture = texture
end

---Returns the rect of the tile.
--It wraps the texture getRect()
--@return Rect
function Tile:getRect()
	return self.texture:getRect()
end

---Returns the width of the tile.
--It wraps the texture.width
--@return int
function Tile:getWidth()
	return self.texture:getWidth()
end

---Returns the height of the tile.
--It wraps the texture.height
--@return int
function Tile:getHeight()
	return self.texture:getHeight()
end

---Sets a property of the tile.
--@param name the name of the property
--@param value the value of the property
function Tile:setProperty(name,value)
	if not self.properties then
		self.properties = {}
	end
	self.properties[name] = value
end

---Gets a property of the tile.
--@param name the name of the property
--@return the value of the property
function Tile:getProperty(name)
	return self.properties and self.properties[name] or nil
end
