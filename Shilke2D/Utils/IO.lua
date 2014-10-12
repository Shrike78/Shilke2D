 --[[---
IO namespace offers functions to easily address fileSystem issues.

When an application is launched, the logical root filesystem is set at the main 
executed lua module level.

The application can read and write only under this filesystem, it's never allowed to 
do things outside it's logical space (only iOS apps require that, but the behaviour
is forced on all devices)

IO module public interface allows to set a working directory relative to the root one and 
to read / execute files inside the logical filesystem space.
--]]

IO = {}

--[[---
Absolute path dir. 
It's initialized when Shilke2D is initialized and it's used to 
handle relative path logic
--]]
IO.__baseDir = MOAIFileSystem.getWorkingDirectory()

---Stores current workingDir, relative to base application path
IO.__workingDir = "/"

--[[---
Returns the absolute app dir on the running device filesystem
@treturn string
--]]
function IO.getBaseDir()
	return IO.__baseDir
end

--[[---
Used to set the working dir. It's always meant as an absolute path starting 
from root application path.
@usage

the following instruction have the exactly same result:
IO.setWorkingDir('Assets')
IO.setWorkingDir('Assets/')
IO.setWorkingDir('/Assets')
IO.setWorkingDir('/Assets/')

@tparam string folder
--]]
function IO.setWorkingDir(folder)
	IO.__workingDir = string.normalizePath("/" .. folder .. "/")
	local path = IO.__baseDir .. folder
	MOAIFileSystem.setWorkingDirectory(path)
end

--[[---
Returns workingDir.
By default returns the working dir related to app root. 
For inner usage it's possible to set a boolean parameter to retrieve the
absolute device path
@tparam[opt=false] bool asDevicePath
@treturn string
--]]
function IO.getWorkingDir(asDevicePath)
	if asDevicePath == true then 
		return IO.__baseDir .. IO.__workingDir:sub(2)
	else
		return IO.__workingDir
	end
end


--[[---
Converts a relative paht into an absolute one.
if 'asDevicePath' then return the path starting from device root 
filesystem, else returns path from application root filesystem
@tparam string path 
@tparam[opt=false] bool asDevicePath
@treturn string
--]]
function IO.getAbsolutePath(path, asDevicePath)
	local path = string.normalizePath(path)
	if not string.starts(path,"/") then
		path = IO.__workingDir .. path
	end
	if asDevicePath then 
		path = IO.__baseDir .. path:sub(2)
	end
	return path
end


--[[---
Checks if a given path is absolute or relative. It's also possible to check
if it's a device absolute path or not
@tparam string path
@tparam[opt=false] bool asDevicePath
@treturn bool
--]]
function IO.isAbsolutePath(path, asDevicePath)
	local path = string.normalizePath(path)
	if not asDevicePath then
		return string.starts(path, "/")
	else
		return string.starts(path, IO.__baseDir)
	end
end


--[[---
Opens a file (it wraps io.open)
@tparam string fileName path to the file to be open, it can be either relative to the currently set
working path, or absolute to the application root.
@tparam[opt='r'] string mode the openfile mode ('r','w','a','r+','w+'). default is 'r'
@treturn[1] file
@return[2] nil
@treturn[2] string error message
--]]
function IO.open(fileName, mode)
	local fn = IO.getAbsolutePath(fileName, true)
	local mode = mode or 'r'
	return io.open(fn, mode)
end


--[[---
Returns raw data for every type of files
@tparam string fileName path to the file to be open, it can be either relative to the currently set
working path, or absolute to the application root.
@return[1] filedata
@return[2] nil
@treturn[2] string error message
--]]
function IO.getFile(fileName)
	local file, err = IO.open(fileName)
	if not file then
		return nil, err
	end
	res = file:read("*all")
	io.close(file)
	return res
end

--[[---
Loads and runs a given file.
@tparam string fileName path to the file to be executed, it can be either relative to the currently set
working path, or absolute to the application root.
@return[1] fileName() the result of the execution of the file
@return[2] nil
@treturn[2] string error message
--]]
function IO.dofile(fileName)
	local fn = IO.getAbsolutePath(fileName, true)
	local chunck, err = loadfile(fn)
	if not chunck then 
		return nil, err 
	end
	return chunck()
end


--[[---
Checks if a given path is a file (not including directory)
@tparam string path the path to check
@treturn bool
--]]
function IO.isFile(path)
	local path = IO.getAbsolutePath(path, true)
	return MOAIFileSystem.checkFileExists(path)
end


--[[---
Checks if a given path is a directory
@tparam string path the path to check
@treturn bool
--]]
function IO.isDirectory(path)
	local path = IO.getAbsolutePath(path, true)
	return MOAIFileSystem.checkPathExists(path)
end

--[[---
Checks if a given path exist (being either a file or a directory) 
@tparam string path the path to check
@treturn bool
--]]
function IO.exists(path)
	return IO.isFile(path) or IO.isDirectory(path)
end

--[[---
Copy a file or a folder
@tparam string src	
@tparam string dst
@treturn bool
--]]
function IO.copy(src, dst)
	local src = IO.getAbsolutePath(src, true)
	local dst = IO.getAbsolutePath(dst, true)
	return MOAIFileSystem.copy(src, dst)
end

--[[---
Renames a file or a folder
@tparam string src	
@tparam string dst
@treturn bool
--]]
function IO.move(src, dst)
	local src = IO.getAbsolutePath(src, true)
	local dst = IO.getAbsolutePath(dst, true)
	return MOAIFileSystem.rename(src,dst)
end


--[[---
Deletes a file
@tparam string path path to the file to delete
@treturn bool success
--]]
function IO.deleteFile(path)
	local path = IO.getAbsolutePath(path, true)
	return MOAIFileSystem.deleteFile(path)
end


--[[---
Deletes a folder. if recursive is true deletes all the subfolders, else it delets
the directory only if empty
@tparam string path path to the directory to delete
@tparam[opt=false] bool recursive If true, the directory and all contents beneath it will be purged. 
Otherwise, the directory will only be removed if empty.
@treturn bool success
--]]
function IO.deleteDirectory(path, recursive)
	local path = IO.getAbsolutePath(path, true)
	local recursive = (recursive == true)
	return MOAIFileSystem.deleteDirectory(path, recursive)
end


--[[---
Lists all the files contained in a directory.
If path is not provided uses current working dir.
@tparam[opt=nil] string path the path to list
@treturn {string} list of file names or nil if the path is not valid
--]]
function IO.lsFiles(path)
	local path = path
	if path then
		path = IO.getAbsolutePath(path, true)
	end
	return MOAIFileSystem.listFiles(path)
end


--[[---
Lists all the sub directories contained in a directory.
If path is not provided uses current working dir.
@tparam[opt=nil] string path the path to list
@treturn {string} list of directory names or nil if the path is not valid
--]]
function IO.lsDirectories(path)
	local path = path
	if path then
		path = IO.getAbsolutePath(path, true)
	end
	return MOAIFileSystem.listDirectories(path)
end


--[[---
Lists all the files and sub directories contained in a directory.
If path is not provided uses current working dir.
@tparam[opt=nil] string path the path to list
@treturn {string} list of directory and file names or nil if the path is not valid
--]]
function IO.ls(path)
	return table.extend(IO.lsDirectories(path), IO.lsFiles(path))
end


--[[---
Creates a folder at 'path' if doesn't exist
@tparam string path the folder to create
--]]
function IO.affirmPath(path)
	local path = IO.getAbsolutePath(path, true)
	MOAIFileSystem.affirmPath(path)
end
