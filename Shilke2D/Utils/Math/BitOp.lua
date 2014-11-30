--[[---
Utility functions to work with bitfields.
It's based on 32 bit bitfields logic and requires lua to be compiled with 64 bit precision
--]]
BitOp = {}

local MOD = 2^32
local MODM = MOD-1
local floor = math.floor
--support table to print bitfield values
local print_table = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}

---logical not operator
function BitOp.bnot(a)
	return MODM - a
end

---logical xor operator
function BitOp.bxor(a,b)
	local c = 0
	for i = 0, 31 do
		-- a had a '0' in bit i
		if (a % 2 == 0) then
			-- b had a '1' in bit i
			if (b % 2 == 1) then
				b = b - 1
				-- set bit i of c to '1' 
				c = c + 2 ^ i
			end
		-- a had a '1' in bit i
		else
			a = a - 1
			-- b had a '0' in bit i
			if (b % 2 == 0) then
				-- set bit i of c to '1' 
				c = c + 2 ^ i
			else
				b = b - 1 
			end
		end
		b = b * 0.5
		a = a * 0.5
	end
	return c
end

---logical and operator
function BitOp.band(a,b)
	return ((a+b) - BitOp.bxor(a,b)) * 0.5
end

---logical or operator
function BitOp.bor(a,b)
	return MODM - BitOp.band(MODM - a, MODM - b)
end

---right shift
--@param a the bitfield to be r shifted
--@param disp the number of shift to perform
function BitOp.rshift(a,disp)
  if disp < 0 then return BitOp.lshift(a,-disp) end
  return floor(a % MOD / 2^disp)
end

---left shift
--@param a the bitfield to be l shifted
--@param disp the number of shift to perform
function BitOp.lshift(a,disp)
  if disp < 0 then return BitOp.rshift(a,-disp) end 
  return (a * 2^disp) % MOD
end

---Tests if a specific flag is true in a bitfield
--@param a the bitfield
--@param flag the flag to test
--@return bool if the flag is set
function BitOp.testflag(a, flag)
  return a % (2 * flag) >= flag
end

---Sets a specific flag in a bitfield
--@param a the bitfield
--@param flag the flag to set
--@return bitfield the modified bitfield
function BitOp.setflag(a, flag)
  if a % (2 * flag) >= flag then
    return a
  end
  return a + flag
end

---Clears a specific flag in a bitfield
--@param a the bitfield
--@param flag the flag to clear
--@return bitfield the modified bitfield
function BitOp.clrflag(a, flag)
  if a % (2 * flag) >= flag then
    return a - flag
  end
  return a
end

---Converts a bitfield to a string
--@param a the bitfield to convert as string
--@return string the bitfield as a string
function BitOp.toString(a)
	local a = a % MOD
	for i = 32, 1, -1 do
		print_table[i] = tostring(floor(a%2))
		a=a/2
	end
	return table.concat(print_table)
end


--[[---
split a bitfield into two bitfields given a mask that indicates low (0) and high (1) bits

@usage

a 		= 00100000000000000000000000000010
mask 	= 11111111000000000000000000000000

l,h 	= BitOp.splitmask(a, mask)

l	=> 00000000000000000000000000000010
h	=> 00100000000000000000000000000000

@param a input bitfield
@param mask the mask bitfield used to split into high, low values
@return l the low part of the bitfield (0 values on the mask)
@return h the hih part of the bitfield (1 values on the mask)
--]]
function BitOp.splitmask(a, mask)
	local m = BitOp.bnot(mask) + 1
	local r = a % m
	return r, a-r
end

--[[---
split a bitfield into two bitfields given a size for the high mask

@usage

a 		= 00100000000000000000000000000010
hbits 	= 8 (=> mask = 11111111000000000000000000000000)

l,h 	= BitOp.splitbits(a, hbits)

l	=> 00000000000000000000000000000010
h	=> 00100000000000000000000000000000

@param a input bitfield
@param hbits the number of bit used to mask high value
@return l the low part of the bitfield (0 values on the mask)
@return h the hih part of the bitfield (1 values on the mask)
--]]
function BitOp.splitbits(a, hbits)
	local m = BitOp.lshift(1, 32 - hbits)
	local r = a % m
	return r, a-r
end
