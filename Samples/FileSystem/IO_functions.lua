require("Shilke2D/include")

function test()
	print(IO.getBaseDir())
	print(IO.getWorkingDir(false))
	print(IO.getWorkingDir(true))
	print(IO.getAbsolutePath("PlanetCute/PlanetCute.lua", false))
	print(IO.getAbsolutePath("PlanetCute/PlanetCute.lua", true))
	print(IO.getAbsolutePath("/PlanetCute/PlanetCute.lua", false))
	print(IO.getAbsolutePath("/PlanetCute/PlanetCute.lua", true))
	print(IO.exists("PlanetCute/PlanetCute.lua"))
	print(IO.isFile("PlanetCute/PlanetCute.lua"))
	print(IO.isDirectory("PlanetCute/PlanetCute.lua"))
	print(IO.exists("PlanetCute"))
	print(IO.isFile("PlanetCute"))
	print(IO.isDirectory("PlanetCute"))
	print(table.dump(IO.lsFiles()))
	print(table.dump(IO.lsDirectories()))
	print(table.dump(IO.ls()))
	IO.affirmPath("test1")
	IO.affirmPath("/test2")
	print(IO.deleteDirectory("test1"))
	print(IO.deleteDirectory("/test2"))
	print(IO.getFile("/Assets/PlanetCute/PlanetCute.lua"))
	print(IO.dofile("PlanetCute/PlanetCute.lua"))
end

--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	test()
	IO.setWorkingDir("Assets")
	test()
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(320,240,60)
shilke2D:start()