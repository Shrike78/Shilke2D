require("Shilke2D/include")

--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	IO.setWorkingDir("Assets/FileSystem")
	local ini = IniParser.fromFile("test.ini")
	print(ini:hasSection("SeCtIoN 1"))
	print(ini:get("section 1", 'string_param_2'))
	print(ini:get("section 1", 'string_param_3'))
	print(ini:get("section 2", 'bool_param_1'))
	print(ini:get("section 2", 'bool_param_2'))
	print(ini:getBool("section 2", 'bool_param_1'))
	print(ini:getBool("section 2", 'bool_param_2'))
	for _,k in pairs(ini:getKeys("Section 3")) do
		print(ini:getNumber("section 3", k))
	end
	print(ini:removeSection("section 0"))
	print(ini:removeSection("section 1"))
	print(ini:removeKey("section 2", "string_param_2"))
	print(ini:removeKey("section 2", "bool_param_2"))
	print(ini:addSection("section 4"))
	print(ini:set("section 4", "test_param", true))
	print(ini:getBool("section 4", "test_param"))
	print(ini:write("test_modified.ini"))
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(320,240,60)
shilke2D:start()