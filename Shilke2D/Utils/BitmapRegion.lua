--[[---
BitmapRegion class it's an helper for handling atlases of packed bitmaps.

A BipmapRegion defines a region over an image, a frame if the packed texture has been 
trimmed to save space/memory, and a rotation flag to idenify 90° clockwise rotated regions

It's the base class of Textures, that can be considered as gpu bitmap regions.

BitmapRegions doesn't store reference to src data. Paired with an image can be used with BitmapData
namespace functions in order to handle 'packed' bitmaps in a similar way to normal bitmaps.
Derived as textures instead provides base logic for packed formats

BitmapRegion members are:

- region: it's the effective area of the original image mapped into BitmapRegion
- frame: defines the actual bounds of the packed image. If the image has been trimmed when packed,
the real rect is wider of the region rect provided. Else it matches.
- rotated: if true the region must be considered as 90° clocwise rotated
- trimmed: if the original image has been trimmed when packed
--]]

BitmapRegion = class()

--[[---
Copy constructor.
@function BitmapRegion:init
@tparam BitmapRegion r
--]]


--[[---
Constructor. Accepts either a set of region / rotated / frame or a BitmapRegion object.

@tparam Rect region
@tparam[opt=false] bool rotated
@tparam[opt=nil] Rect frame
--]]
function BitmapRegion:init(region, rotated, frame)
	
	--handle 'copy constructor' logic
	if class_type(region) == BitmapRegion then
		self.region = c.region:clone()
		frame = c.frame:clone()
		self.rotated = c.rotated
		self.trimmed = c.trimmed
		return
	end
	
	self.region = region:clone()
	self.rotated = rotated == true
	if frame then
		self.frame = frame:clone()
		self.trimmed = (frame.w*frame.h ~= region.w*region.h)
	else
		self.trimmed = false
		if self.rotated then
			self.frame = Rect(0, 0, self.region.h, self.region.w)
		else
			self.frame = Rect(0, 0, self.region.w, self.region.h)
		end
	end
end


--[[---
clear inner struct
--]]
function BitmapRegion:dispose()
	self.region = nil
	self.frame = nil
end

--[[---
Copy the params of another BitmapRegion
@tparam BitmapRegion r
@treturn BitmapRegion self
--]]
function BitmapRegion:copy(r)
	self.region:copy(r.region)
	self.frame:copy(r.frame)
	self.rotated = r.rotated
	self.trimmed = r.trimmed
	return self
end

--[[---
Returns a copy of the region Rect.
@tparam[opt=nil] Rect resultRect if provided is filled and returned
@treturn Rect
--]]
function BitmapRegion:getRegion(resultRect)
	local res = resultRect or Rect()
	res:copy(self.region)
	return res
end

--[[---
Returns a copy of the frame Rect.
@tparam[opt=nil] Rect resultRect if provided is filled and returned
@treturn Rect
--]]
function BitmapRegion:getFrame(resultRect)
	local res = resultRect or Rect()
	res:copy(self.frame)
	return res
end


--[[---
Returns the width in pixels
@treturn int width
--]]
function BitmapRegion:getWidth()
	return self.frame.w
end

--[[---
Returns the height in pixels
@treturn int height
--]]
function BitmapRegion:getHeight()
	return self.frame.h
end

--[[---
Returns the size in pixels
@treturn int width
@treturn int height
--]]
function BitmapRegion:getSize()
	return self.frame.w, self.frame.h
end

