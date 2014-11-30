--[[---
A MovieClip is a simple way to display an animation depicted by a list 
of textures. 

It inherits from Image and implements IAnimatable interface.

Pass the frames of the movie in a vector of textures to 
the constructor. The movie clip will have the width and height of the 
first frame. If you group your frames with the help of a texture atlas
(which is recommended), use the "getTextures" method of the atlas to 
receive the textures in the correct (alphabetic) order.

It's possible to specify the desired framerate via the constructor. 
   
The methods "play" and "pause" control playback of the movie.
The "play" method accept a startFrame value. by default the 
animation start at frame 1

By default an animation is played once. It's possible to set a 
repeatCount value to increase the number of repetition. 
A negative repeatCount means infinite loops.

An Event of type Event.COMPLETED is raised when the movie 
finished playback of a single iteration. 

The frame list can be inverted calling the "invertFrames" method
--]]

MovieClip = class(Image, IAnimatable)

---Init requires a list of textures, fps and pivotMode
--@param textures a list of textures that rapresents the frames of the animation
--@param fps the animation fps value. If nil, default is 12
--@param pivotMode default value is CENTER
function MovieClip:init(textures,fps,pivotMode)
	--assert(textures)
	Image.init(self,textures[1],pivotMode)
	self.fps = fps or 12
	self.animTime = 1 / self.fps
	self.textures = textures
	self.numFrames = #textures
	self.currentFrame = 1
	self.paused = false
	self.playing = false
	self.elapsedTime = 0
	self.repeatCount = 1
	self.eventCompleted = Event(Event.COMPLETED)
end

function MovieClip:dispose()
	Image.dispose(self)
	table.clear(self.textures)
	self.paused = false
	self.playing = false
	self.currentFrame = 1
	self.elapsedTime = 0
	self.repeatCount = 1
end

--[[---
Returns a new MovieClip that shares the same texture list (frames) and fps
@param bClonePivot boolean if true set the same pivotMode / pivot point, 
else set defaul pivotMode CENTER
@return MovieClip
--]]
function MovieClip:clone(bClonePivot)
	if not bClonePivot then
		return MovieClip(self.textures,self.fps)
	else
		local obj = MovieClip(self.textures,self.fps,self._pivotMode)
		if self._pivotMode == PivotMode.CUSTOM then
			obj:setPivot(self:getPivot())
		end
		return obj
	end
end

---Returns the number of frames handled by the animation
--@return number of frames
function MovieClip:getNumFrames()
	return self.numFrames
end

---Returns the number of the current displayed frame
---@return current displayed frame
function MovieClip:getCurrentFrame()
	return self.currentFrame
end

---Starts the animation
--@param startFrame the frame where to begin with the animation. Default is 1
--@param repeatCount the number of iteration. Default is 1. repeatCount <= 0 means infinite loop.
function MovieClip:play(startFrame, repeatCount)
	if(startFrame and startFrame > 0 and 
		startFrame <= self.numFrames) then
		self.currentFrame = startFrame
	else
		self.currentFrame = 1
	end
	if repeatCount then
		self.repeatCount = repeatCount
	end
	self.paused = false
	self.playing = true
	self.elapsedTime = 0
	self.currentCount = 0
	self:setTexture(self.textures[self.currentFrame])
end

---Inverts the animation frame
--can be done only when the animation is not playing, else does nothing
function MovieClip:invertFrames()
	if not self.playing then
		self.textures = table.invert(self.textures)
	end
end

---Sets the repeatCount for this animation
--@param repeatCount the number of iteration. repeatCount <= 0 means infinite loop.
function MovieClip:setRepeatCount(repeatCount)
	self.repeatCount = repeatCount
end

---Gets the repeatCount for this animation
--@return repeatCount. values <= 0 means infinite loop.
function MovieClip:getRepeatCount()
	return self.repeatCount
end

---Pause / unpause the animation in pause
--@param enabled set / unset pause status. Has no effects if the animation is stopped.
function MovieClip:setPause(enabled)
	self.paused = bPause
end

---Get the pause status
--return boolean if the animation is paused
function MovieClip:isPaused()
	return self.paused
end

---Stops the current animation and reset timing infos
function MovieClip:stop()
	self.paused = false
	self.playing = false   
	self.elapsedTime = 0
	self.currentCount = 0
end

---IAnimatable interface implementation.
--@param deltaTime millisec elapsed since last frame
function MovieClip:advanceTime(deltaTime)
	if self.playing and not self.paused then
		self.elapsedTime = self.elapsedTime + deltaTime
		if self.elapsedTime > self.animTime then
			self.currentFrame = (self.currentFrame % self.numFrames) + 1
			if self.currentFrame == 1 and 
					(self.currentCount < self.repeatCount or 
					self.repeatCount <=0 ) then

				self.currentCount = self.currentCount + 1

				self:dispatchEventByType(Event.COMPLETED)
				
				if self.currentCount == self.repeatCount then
					self:stop()
				else
					self:setTexture(self.textures[self.currentFrame])
				end
			else
				self:setTexture(self.textures[self.currentFrame])
			end
			self.elapsedTime = self.elapsedTime - self.animTime
		end
	end
end
