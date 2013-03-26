 --[[---
IO namespace offers functions to easily addressed fileSystem issues.
--]]

IO = {}

---Absolute path dir. 
--It's initialized when Shilke2D is initialized and it's used to 
--handle relative path logic
IO.__baseDir = MOAIFileSystem.getWorkingDirectory()

---Store current workingDir, relative to base application path
IO.__workingDir = ""

--[[---
Used to set the working dir. It's meant as a path starting 
always from root application path
@param folder string
--]]
function IO.setWorkingDir(folder)
	IO.__workingDir = ("/" .. folder):gsub("//","/")
	local path = IO.__baseDir .. folder
	MOAIFileSystem.setWorkingDirectory(path)
end

---Returns the absolut app dir
--@return string
function IO.getBaseDir()
	return IO.__baseDir
end

--[[---
Returns workingDir.
if "asDevicePath" then return the path starting from device root 
filesystem, else returns path from application root filesystem
@param asDevicePath bool
@return string
--]]
function IO.getWorkingDir(asDevicePath)
	if asDevicePath == true then 
		return IO.__baseDir .. IO.__workingDir
	else
		return IO.__workingDir
	end
end

--[[---
Converts a relative paht into an absolute one.
if "asDevicePath" then return the path starting from device root 
filesystem, else returns path from application root filesystem
@param path string
@param asDevicePath bool
@return string
--]]
function IO.getAbsolutePath(path, asDevicePath)
	local path = path:gsub("\\","/")
	if not string.starts(path,"/") then
		path = IO.__workingDir .. "/" .. path
	end
	if asDevicePath == true then 
		path = IO.__baseDir .. path
	end
	return path:gsub("//","/")
end

---Returns raw data for every type of files
--@param fileName string
--@return file or nil if an error raises
--@return nil or error message if an error raises
function IO.getFile(fileName)
	local fn = fileName
	if string.starts(fn,"/") then
		fn = IO.__baseDir .. fn
	end
    local file,err = io.open(fn,"r")
	local res = nil
    if not err then
        res = file:read("*all")
        io.close(file)
    end
	return res,err
end

---Allows to set a path for dofile (by default use MOAI WorkingDir
function IO.dofile(fileName)
	local fn = fileName
	if string.starts(fn,"/") then
		fn = IO.__baseDir .. fn
	end
	local chunck,err = loadfile(fn)
	if not chunck then return nil, err end
	return chunck()
end
