--KEY_CTRL_DIFF = 96 ???
KEY_DEL = 8
KEY_RETURN = 13
KEY_ESC = 27
KEY_SPACE = 32
KEY_CANC = 127
KEY_F1 = 257
KEY_F2 = 258
KEY_F3 = 259
KEY_F4 = 260
KEY_F5 = 261
KEY_F6 = 262
KEY_F7 = 263
KEY_F8 = 264
KEY_F9 = 265
KEY_F10 = 266
KEY_F11 = 267
KEY_F12 = 268
KEY_LEFT = 356
KEY_UP = 357
KEY_RIGHT = 358
KEY_DOWN = 359
KEY_PAGE_UP = 360
KEY_PAGE_DOWN = 361

function KEY(k)
	return string.byte(k)
end

function isKeyUp(k)
	local k = type(k) == 'number' and string.char(k) or k
	return MOAIInputMgr.device.keyboard:keyIsUp(k)
end

function isKeyDown(k)
	local k = type(k) == 'number' and string.char(k) or k
	return MOAIInputMgr.device.keyboard:keyIsDown(k)
end
