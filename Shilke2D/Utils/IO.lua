-- IO

IO = {}

-- Get initialized when Shilke2D is initialized and it's used to handle relative path logic
-- To be checked with iOS/Android
IO.__baseDir = MOAIFileSystem.getWorkingDirectory()
--IO.__baseDir = IO.__baseDir:sub(1,-2)

IO.__workingDir = ""

--setWorkingDir is meant to be used to set a working dir starting ALWAYS from root, so 
--having 'folder' starting with "/" is optional
function IO.setWorkingDir(folder)
	IO.__workingDir = ("/" .. folder):gsub("//","/")
	local path = IO.__baseDir .. folder
	MOAIFileSystem.setWorkingDirectory(path)
end

function IO.getBaseDir()
	return IO.__baseDir
end

--if "asDevicePath" then return the path starting from device root filesystem
--else return path from application root filesystem
function IO.getWorkingDir(asDevicePath)
	if asDevicePath == true then 
		return IO.__baseDir .. IO.__workingDir
	else
		return IO.__workingDir
	end
end

--if "asDevicePath" then return the path starting from device root filesystem
--else return path from application root filesystem
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

--get file returns raw data for each type of files
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

-- allows to set a path for dofile (by default use MOAI WorkingDir
function IO.dofile(fileName)
	local fn = fileName
	if string.starts(fn,"/") then
		fn = IO.__baseDir .. fn
	end
	local chunck,err = loadfile(fn)
	if not chunck then return nil, err end
	return chunck()
end
