---Set of utilities and constants for BitmapDatas (MOAIImages)

---define the possible color transform used when loading/converting an image
ColorTransform = 
{
	NONE				= 0,							--no transformation
	POW_TWO 			= MOAIImage.POW_TWO, 			--image is forced to be pow two sized 
	QUANTIZE 			= MOAIImage.QUANTIZE, 			--reduce the number of used colors
	TRUECOLOR 			= MOAIImage.TRUECOLOR, 			--convert indexed to truecolor images
	PREMULTIPLY_ALPHA	= MOAIImage.PREMULTIPLY_ALPHA	--r,g,b values are premultiplied by alpha value
}

--[[---
BitmapData namespace contains a set of functionalities that extend MOAIImage support.
--]]
BitmapData = {}

--[[---
transform the transparent pixels of a MOAIImage forcing the r,g,b components to a given value
@tparam MOAIImage img the img to transform
@param r (0,255) value or Color object or hex string or int32 color
@param g (0,255) value or nil
@param b (0,255) value or nil
@treturn MOAIImage a reference to the image itself
--]]
function BitmapData.setTransparentColor(img, r, g, b)
	local r,g,b,a = Color._toNormalizedRGBA(r,g,b)
	local w,h = img:getSize()
	for x = 0,w-1,1 do
		for y = 0,h-1,1 do
			_,_,_,a = img:getRGBA(x,y)
			if a == 0 then
				img:setRGBA(x,y,r,g,b,a)
			end
		end
	end
	return img
end

--[[---
transform the pixels of a MOAIImage premultiplying the alpha value of each pixel for 
rgb components
@tparam MOAIImage img the MOAIImage to transform
@treturn MOAIImage a reference to the image itself
--]]
function BitmapData.premultiplyAlpha(img)
	local w,h = img:getSize()
	for x = 0,w-1,1 do
		for y = 0,h-1,1 do
			local r,g,b,a = img:getRGBA(x,y)
			if a ~= 1 then
				img:setRGBA(x,y,r*a,g*a,b*a,a)
			end
		end
	end
	return img
end

--[[---
Load a raw image. It's possible to specify a color transformation on load, with PREMULTIPLY_ALPHA as 
default value.
If straight alpha is used configure accordingly the alpha mode of the displayObjects that are going to use
the loaded image.
@string fileName the name of the raw image to load
@tparam[opt=ColorTransform.PREMULTIPLY_ALPHA] ColorTransform transformOptions 
@treturn[1] MOAIImage
@return[2] nil
@treturn[2] string  error message
--]]
function BitmapData.fromFile(fileName, transformOptions)
	local transformOptions = transformOptions or ColorTransform.PREMULTIPLY_ALPHA
	local img = MOAIImage.new()
	-- if the file is "absolute" we need to load the image with absolute 'asDevice' file Name
	local absFileName = IO.getAbsolutePath(fileName, true)
	img:load(absFileName, transformOptions)
	local w,h = img:getSize()
	if w == 0 and h == 0 then
		return nil, fileName .. " is not a valid path"
	end
    return img
end

-----------------------------------------

--default return value for getRegionColor32
local function defColor32()
	return 0
end

--default return value for getRegionRGBA call
local function defRGBA()
	return 0,0,0,0
end

-- _getColor is used by getRegionColor32 and getRegionRGBA for getting color information from
-- a region based image. the implementation is different based on simulation coords and is splitted
-- as definition in order to avoid multiple if/else inside the function
local __getColor = nil
local __helperRect = Rect()

if __USE_SIMULATION_COORDS__ then
	
	__getColor = function(srcData, x, y, bmpRegion, colorFunc, defColorFunc)
		
		local region = bmpRegion.region
		local rotated = bmpRegion.rotated
		local frame = bmpRegion.frame
		
		if bmpRegion.trimmed then
			local rh,rw
			if rotated then
				rh,rw = region.w, region.h
			else
				rh,rw = region.h, region.w
			end
			if x < frame.x or x > frame.x + rw then
				return defColorFunc()
			elseif y < (frame.h - frame.y - rh) or y > (frame.h - frame.y) then
				return defColorFunc()
			end
			x = x - frame.x
			y = y - (frame.h - frame.y - rh)
		end
		local _x, _y = region.x, region.y
		if not rotated then
			_x = _x + x
			_y = _y + region.h - y
		else
			_x = _x + y 
			_y = _y + x
		end
		return colorFunc(srcData,_x,_y)
	end
		
else --__USE_SIMULATION_COORDS__
	
	__getColor = function(srcData, x, y, bmpRegion, colorFunc, defColorFunc)
		
		local region = bmpRegion.region
		local rotated = bmpRegion.rotated
		local frame = bmpRegion.frame
		
		if bmpRegion.trimmed then
			local rh,rw
			if rotated then
				rh,rw = region.w, region.h
			else
				rh,rw = region.h, region.w
			end
			if x < frame.x or x > frame.x + rw then
				return defColorFunc()
			elseif y < frame.y or y > frame.y + rh then
				return defColorFunc()
			end
			x = x - frame.x
			y = y - frame.y
		end
		local _x, _y = region.x, region.y
		if not rotated then
			_x = _x + x
			_y = _y + y
		else
			_x = _x + (region.w - 1) - y 
			_y = _y + x
		end
		return colorFunc(srcData,_x,_y)
	end
	
end

--[[---
Copy from srcData a packed image content.
It's also possible to define a copy offset using<br>
optional x,y params

@tparam MOAIImage dst
@tparam MOAIImage src
@tparam BitmapRegion bmpRegion
@int[opt=0] x
@int[opt=0] y
--]]	
function BitmapData.copyRegion(dst, src, bmpRegion, x, y)
	
	local region = bmpRegion.region
	local framex, framey = bmpRegion.frame.x, bmpRegion.frame.y
	
	local x = x or 0
	local y = y or 0
	if not bmpRegion.rotated then
		dst:copyBits(	src, 
						region.x, region.y,
						framex + x, framey + y, 
						region.w, region.h)
	else
		local basex = region.x + (region.w - 1)
		local basey = y + framey
		local dy, sx
		for i = 0, region.w do
			sx = basex - i
			dy = basey + i
			for j = 0, region.h do
				dst:setColor32(x + framex + j, dy, src:getColor32(sx, region.y + j))
			end
		end
	end
end

--[[---
Create a new image as a copy of a packed image
Resulting image is not rotated and not packed but can be optionally framed
@tparam MOAImage src
@tparam BitmapRegion bmpRegion
@bool[opt=false] keepFrame
@treturn MOAIImage
@treturn BitmapRegion nil if keepFrame is false
--]]	
function BitmapData.cloneRegion(src, bmpRegion, keepFrame)
	local dst = MOAIImage.new()
	local region = nil
	--keep frame true force the creation of a new image not rotated but framed, so
	--with a resulting region with the same frame value of the provided bmpRegion
	if keepFrame then
		--the resulting texture has the size of the inner unrated region
		local w,h = bmpRegion.region.w, bmpRegion.region.h
		if bmpRegion.rotated then
			w,h = h,w
		end
		dst:init(w, h, src:getFormat())
		--the copyRegion is called without frame informations
		BitmapData.copyRegion(dst, src, BitmapRegion(bmpRegion.region, bmpRegion.rotated))
		--the returned region has only frame information
		region = BitmapRegion(Rect(0,0,w,h), false, bmpRegion.frame)
	else
		local w,h = bmpRegion:getSize()
		dst:init(w, h, src:getFormat())
		BitmapData.copyRegion(dst, src, bmpRegion)
	end
	return dst, region
end

--[[---
Get a pixel value as 32bit integer. 
@tparam MOAImage img
@int x
@int y
@tparam[opt=nil] BitmapRegion bmpRegion
@treturn number
--]]	
function BitmapData.getColor32(img, x, y, bmpRegion)
	if not bmpRegion then
		return img:getColor32(x,y)
	end
	return __getColor(img, x, y, bmpRegion, img.getColor32, defColor32)
end
	
--[[---
Get a pixel value as r,g,b,a values
@tparam MOAImage img
@int x
@int y
@tparam[opt=nil] BitmapRegion bmpRegion
@treturn number r [0..1]
@treturn number g [0..1]
@treturn number b [0..1]
@treturn number a [0..1]
--]]	
function BitmapData.getRGBA(img, x, y, bmpRegion)
	if not bmpRegion then
		return img:getRGBA(x,y)
	end
	return __getColor(img, x, y, bmpRegion, img.getRGBA, defRGBA)
end
	
--[[---
Get a pixel value as Color
@tparam MOAImage img
@int x
@int y
@tparam[opt=nil] BitmapRegion bmpRegion
@treturn Color
--]]	
function BitmapData.getColor(img, x, y, bmpRegion)
	return Color.fromNormalizedValues(BitmapData.getRGBA(img, x, y, bmpRegion))
end
	
					
--[[---
Checks pixel perfect overlap of two images.
Depending on simulation coords the point 0,0
can be the top or the bottom left point

@tparam MOAIImage i1 image 1
@number x1 top/bottom left position x coord of image1
@number y1 top/bottom left position y coord of image1
@int a1 [0..255] alpha treshold to consider image1 pixel transparent
@tparam MOAIImage i2 image 2
@number x2 top/bottom left position x coord of image2
@number y2 top/bottom left position y coord of image2
@int a2 [0..255] alpha treshold to consider image2 pixel transparent
@int[opt=1] step the precision of the test. higher values produce faster but less accurate results
i.e.: if opt == 2 only a quarter of the overlapping pixels are tested
@treturn boolean
--]]
function BitmapData.hitTest(i1,x1,y1,a1,i2,x2,y2,a2,step)
	
	local w1,h1 = i1:getSize()
	local w2,h2 = i2:getSize()
	
	local r1 = Rect(x1,y1,w1,h1)
	local r2 = Rect(x2,y2,w2,h2)
	
	local step = step or 1
	
	--check for rect intersection
	if not r1:intersects(r2) then 
		return false 
	end	
	
	--alpha values are [0,255]
	local a1 = a1/255
	local a2 = a2/255
	
	--adjust r1,r2 to be intersection of the original rects
	if x1 <= x2 then
		r1.x = x2 - x1
		r2.x = 0
		r1.w = r1.w - r1.x
	else
		r1.x = 0
		r2.x = x1 - x2
		r1.w = r2.w - r2.x
	end
	if y1 <= y2 then
		r1.y = y2 - y1
		r2.y = 0
		r1.h = r1.h - r1.y
	else
		r1.y = 0
		r2.y = y1 - y2
		r1.h = r2.h - r2.y
	end
	
	--skip cases of edge collision
	if r1.w == 0 or r1.h == 0 then return false end
	
	if not __USE_SIMULATION_COORDS__ then	
		for i = 1,r1.w,step do
			for j = 1,r1.h,step do
				local _,_,_,a = i1:getRGBA(r1.x + i, r1.y + j)
				if a > a1 then
					_,_,_,a = i2:getRGBA(r2.x + i, r2.y + j)
					if a > a2 then
						return true
					end
				end
			end
		end
	else --__USE_SIMULATION_COORDS__
		r1.y = h1 - r1.y
		r2.y = h2 - r2.y
		
		for i = 1,r1.w,step do
			for j = 1,r1.h,step do
				local _,_,_,a = i1:getRGBA(r1.x + i, r1.y -j)
				if a > a1 then
					_,_,_,a = i2:getRGBA(r2.x + i, r2.y - j)
					if a > a2 then
						return true
					end
				end
			end
		end

	end
	return false
end

--[[---
Checks pixel perfect overlap of two images.
Depending on simulation coords the point 0,0
can be the top or the bottom left point

@tparam MOAIImage i1 image 1
@number x1 top/bottom left position x coord of image1
@number y1 top/bottom left position y coord of image1
@int a1 [0..255] alpha treshold to consider image1 pixel transparent
@tparam MOAIImage i2 image 2
@number x2 top/bottom left position x coord of image2
@number y2 top/bottom left position y coord of image2
@int a2 [0..255] alpha treshold to consider image2 pixel transparent
@tparam[opt=nil] BitmapRegion bmpRegion1
@tparam[opt=nil] BitmapRegion bmpRegion2
@int[opt=1] step the precision of the test. higher values produce faster but less accurate results
i.e.: if opt == 2 only a quarter of the overlapping pixels are tested
@treturn boolean
--]]
function BitmapData.hitTestEx(i1,x1,y1,a1,i2,x2,y2,a2, bmpRegion1, bmpRegion2, step)
	
	if not bmpRegion1 and not bmpRegion2 then
		return BitmapData.hitTest(i1,x1,y1,a1,i2,x2,y2,a2,step)
	end
	
	local reg1, rot1, frame1, trimmed1, reg2, rot2, frame2, trimmed2
	local step = step or 1
	
	if bmpRegion1 then
		reg1 = bmpRegion1.region
		rot1 = bmpRegion1.rotated
		frame1 = bmpRegion1.frame
		trimmed1 = bmpRegion1.trimmed
	end
	
	if bmpRegion2 then
		reg2 = bmpRegion2.region
		rot2 = bmpRegion2.rotated
		frame2 = bmpRegion2.frame
		trimmed2 = bmpRegion2.trimmed
	end
	
	if trimmed1 then
		x1 = x1+frame1.x
		if not __USE_SIMULATION_COORDS__ then
			y1 = y1+frame1.y
		else
			local rh = rot1 and reg1.w or reg1.h
			y1 = y1 + (frame1.h - rh - frame1.y)
		end
	end
	
	if trimmed2 then
		x2 = x2+frame2.x
		if not __USE_SIMULATION_COORDS__ then
			y2 = y2+frame2.y
		else
			local rh = rot2 and reg2.w or reg2.h
			y2 = y2 + (frame2.h - rh - frame2.y)
		end
	end
	
	local w1,h1,w2,h2,o1x,o1y,o2x,o2y
	
	if reg1 then
		w1,h1 = reg1.w, reg1.h
		o1x,o1y = reg1.x, reg1.y
	else
		w1,h1 = i1:getSize()
		o1x,o1y = 0,0
	end
	
	if reg2 then
		w2,h2 = reg2.w, reg2.h
		o2x,o2y = reg2.x, reg2.y
	else
		w2,h2 = i2:getSize()
		o2x,o2y = 0,0
	end

	if rot1 then
		w1,h1 = h1,w1
	end
	if rot2 then
		w2,h2 = h2,w2
	end
	
	local r1 = Rect(x1,y1,w1,h1)
	local r2 = Rect(x2,y2,w2,h2)
	
	--check for intersection
	if not r1:intersects(r2) then 
		return false 
	end
 
	--alpha values are [0,255]
	local a1 = a1/255
	local a2 = a2/255
	
	--adjust r1,r2 to be intersection of the original rects
	if x1 <= x2 then
		r1.x = x2 - x1
		r2.x = 0
		r1.w = r1.w - r1.x
	else
		r1.x = 0
		r2.x = x1 - x2
		r1.w = r2.w - r2.x
	end
	if y1 <= y2 then
		r1.y = y2 - y1
		r2.y = 0
		r1.h = r1.h - r1.y
	else
		r1.y = 0
		r2.y = y1 - y2
		r1.h = r2.h - r2.y
	end
	
	--skip cases of edge collision
	if r1.w == 0 or r1.h == 0 then return false end

	if not __USE_SIMULATION_COORDS__ then

		if not rot1 and not rot2 then
			local _x1,_y1 = (o1x + r1.x), (o1y + r1.y)
			local _x2,_y2 = (o2x + r2.x), (o2y + r2.y)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 + i, _y1 + j)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 + i, _y2 + j)
						if a > a2 then
							return true
						end
					end
				end
			end
		elseif not rot1 and rot2 then
			local _x1,_y1 = (o1x + r1.x), (o1y + r1.y)
			local _x2,_y2 = (o2x + h2 - r2.y), (o2y + r2.x)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 + i, _y1 + j)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 - j, _y2 + i)
						if a > a2 then
							return true
						end
					end
				end
			end
		elseif rot1 and not rot2 then
			local _x1,_y1 = (o1x + h1 - r1.y), (o1y + r1.x)
			local _x2,_y2 = (o2x + r2.x), (o2y + r2.y)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 - j, _y1 + i)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 + i, _y2 + j)
						if a > a2 then
							return true
						end
					end
				end
			end
		elseif rot1 and rot2 then
			local _x1,_y1 = (o1x + h1 - r1.y), (o1y + r1.x)
			local _x2,_y2 = (o2x + h2 - r2.y), (o2y + r2.x)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 - j, _y1 + i)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 - j, _y2 + i)
						if a > a2 then
							return true
						end
					end
				end
			end
		end
	else --__USE_SIMULATION_COORDS__
		if not rot1 and not rot2 then
			local _x1,_y1 = (o1x + r1.x), (o1y + h1 - r1.y)
			local _x2,_y2 = (o2x + r2.x), (o2y + h2 - r2.y)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 + i, _y1 -j)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 + i, _y2 - j)
						if a > a2 then
							return true
						end
					end
				end
			end
		elseif not rot1 and rot2 then
			local _x1,_y1 = (o1x + r1.x), (o1y + h1 - r1.y)
			local _x2,_y2 = (o2x + r2.y), (o2y + r2.x)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 + i, _y1 -j)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 + j, _y2 + i)
						if a > a2 then
							return true
						end
					end
				end
			end
		elseif rot1 and not rot2 then
			local _x1,_y1 = (o1x + r1.y), (o1y + r1.x)
			local _x2,_y2 = (o2x + r2.x), (o2y + h2 - r2.y)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 + j, _y1 + i)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 + i, _y2 - j)
						if a > a2 then
							return true
						end
					end
				end
			end
		elseif rot1 and rot2 then
			local _x1,_y1 = (o1x + r1.y), (o1y + r1.x)
			local _x2,_y2 = (o2x + r2.y), (o2y + r2.x)
			for i = 1,r1.w,step do
				for j = 1,r1.h,step do
					local _,_,_,a = i1:getRGBA(_x1 + j, _y1 + i)
					if a > a1 then
						_,_,_,a = i2:getRGBA(_x2 + j, _y2 + i)
						if a > a2 then
							return true
						end
					end
				end
			end
		end
	end
	return false
end