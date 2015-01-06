--[[---
ObjectPool namespace offers a fast way to recycle and reuse objects
reducing gargace collection and increasing performances.

The pool handle object based on class, it's not used for generic tables.
It works with classes that have a default empty constructor.
--]]
ObjectPool = {}

ObjectPool._pool = {}

---
-- Inner function get/create the pool for objType 
-- @tparam class objType the class of the pooled objects 
-- @treturn {objType}
function ObjectPool._getPool(objType)
	if not ObjectPool._pool[objType] then
		ObjectPool._pool[objType] = {}
	end
	return ObjectPool._pool[objType]
end


---
-- Gets the number of available pooled objects of a given type
-- @tparam class objType the class of the pooled objects 
-- @treturn int the number of the available objects for the given type
function ObjectPool.getAvailableObjs(objType)
	return #ObjectPool._getPool(objType)
end

---
-- Reserves a certain number of pooled objects of a given type
-- @tparam class objType
-- @tparam int number
function ObjectPool.reserve(objType, number)
	local pool = ObjectPool._getPool(objType)
	local needed = number - #pool
	for i=1,needed do
		pool[#pool+1] = objType()
	end
end

---
-- Force the size of the pool for a given object type. 
-- It can be used in replace of 'reserve' or to clean memory
-- after an heavy usage of resources
-- @tparam class objType
-- @tparam int number
function ObjectPool.resize(objType, number)
	local pool = ObjectPool._getPool(objType)
	local free = #pool
	--like 'reserve'
	if free < number then
		local needed = number - free
		for i=1,needed do
			pool[#pool+1] = objType()
		end
	--remove exceeding objects, freeing up memory
	elseif free > number then
		local exceeded = free - number
		for i=1,exceeded do
			table.remove(pool)
		end
	end
end


---
-- Return an object of the given type. 
-- If not available in pool it creats a new one 
-- (requires default constructor)
-- @tparam class objType
-- @treturn objType instance
function ObjectPool.getObj(objType)
	local pool = ObjectPool._getPool(objType)
	if #pool > 0 then
		return table.remove(pool)
	else
		return objType()
	end
end


---
-- Puts a given object into a pool based on its class
-- @param obj a generic class object
function ObjectPool.recycleObj(obj)
	local objType = class_type(obj)
	local pool = ObjectPool._getPool(objType)
	pool[#pool+1] = obj
end


---
-- Puts given objects into pools based on theirs classes
-- @param ... generic class objects
function ObjectPool.recycleObjs(...)
	local num = select('#', ...)
	local obj
	local objType
	for i=1,num do
		obj = select(i, ...)
		if obj then
			objType = class_type(obj)
			local pool = ObjectPool._getPool(objType)
			pool[#pool+1] = obj
		end
	end
end


---
-- Remove all the pooled objects of a given type. If no type is provided, 
-- it clears all the pooled objects.
-- @param[opt=nil] objType a generic class object
function ObjectPool.clear(objType)
	if objType then
		table.clear(ObjectPool._getPool(objType))
	else
		for _,p in pairs(ObjectPool._pool) do
			table.clear(p)
		end
		table.clear(ObjectPool._pool)
	end
end
