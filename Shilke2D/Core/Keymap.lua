--[[---
KeyMap definition based on GLUT host keymap

Special keys (like UP,DOWN,LEFT,RIGHT) are enabled only on custom GLUT MOAI hosts

Moreover some utilities are provided to handle keys
--]]

---Special Keys
Key = {
	DEL = 8,
	RETURN = 13,
	ESC = 27,
	SPACE = 32,
	CANC = 127,
	F1 = 257,
	F2 = 258,
	F3 = 259,
	F4 = 260,
	F5 = 261,
	F6 = 262,
	F7 = 263,
	F8 = 264,
	F9 = 265,
	F10 = 266,
	F11 = 267,
	F12 = 268,
	LEFT = 356,
	UP = 357,
	RIGHT = 358,
	DOWN = 359,
	PAGE_UP = 360,
	PAGE_DOWN = 361
}

---Translate a character into a keycode
-- @param c the character to convert
-- @return the key code of the character
function KEY(c)
	return string.byte(c)
end

---Check if a given key is UP
-- @param k the key to check the status
function isKeyUp(k)
	local k = type(k) == 'number' and string.char(k) or k
	return MOAIInputMgr.device.keyboard:keyIsUp(k)
end

---Check if a given key is DOWN
-- @param k the key to check the status
function isKeyDown(k)
	local k = type(k) == 'number' and string.char(k) or k
	return MOAIInputMgr.device.keyboard:keyIsDown(k)
end
