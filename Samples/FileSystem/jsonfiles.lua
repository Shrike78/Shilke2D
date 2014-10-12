__USE_MOAIJSONPARSER__ = false

require("Shilke2D/include")

--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	IO.setWorkingDir("Assets/FileSystem")
	-- Lua script:
	local t = { 
		["name1"] = "value1",
		["name2"] = {1, false, true, 23.54, "a \021 string"},
		name3 = nil,
		name4 = setup
	}

	local json = Json.encode(t)
	print (json) 
	--> {"name1":"value1","name3":null,"name2":[1,false,true,23.54,"a \u0015 string"]}

	local t2 = Json.decode(json)
	print(t2.name2[4])
	--> 23.54
		
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(320,240,60)
shilke2D:start()