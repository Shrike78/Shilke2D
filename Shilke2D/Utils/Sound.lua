--If MOAIUntzSystem is disabled, an stub interface is created to make the game run without any problem
if MOAIUntzSystem then
	function Sound()
		return MOAIUntzSound.new()
	end
else
	Sound = class()
	
	function Sound:init()
		self.isPlaying = false
		self.isPaused = false
		self.isLooping = false
		self.volume = 0
		self.fileName = nil
	end
	
	function Sound:load(fileName)
		self.fileName = fileName
	end
	
 	function Sound:getFilename()
		return self.fileName
	end
	
 	function Sound:getLength()
		return 0
	end

 	function Sound:setVolume(value)
		self.volume = value
	end
	
 	function Sound:getVolume()
		return self.volume
	end
	
 	function Sound:setLooping(value)
		self.isLooping = value
	end
	
 	function Sound:isLooping()
		return self.isLooping
	end
	
 	function Sound:play()
		self.isPlaying = true
		self.isPaused = false
	end
	
 	function Sound:pause()
		self.isPaused = true
	end
	
	function Sound:stop()
		self.isPlaying = false
		self.isPaused = false
	end
	
 	function Sound:isPaused()
		return self.isPaused
	end
	
 	function Sound:isPlaying()
		return self.isPlaying
	end
 
end
