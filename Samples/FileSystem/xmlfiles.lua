require("Shilke2D/include")

--Setup is called once at the beginning of the application, just after Shilke2D initialization phase
--here everything should be set up for the following execution
function setup()
	IO.setWorkingDir("Assets/FileSystem")
	local xml,res = XmlNode.fromFile("test.xml")
	for k,v in pairs(xml:getChildren("SubTexture")) do
		print(v:getAttribute("name"))
	end
	local n = xml:addChild(XmlNode("test_2",{name = "value"},"text",nil))
	n:addAttribute("url", "/usr/local")
	print(xml:strDump())
	xml:write("test_copy.xml")
end

--shilke2D initialization. it requires width, height and fps. Optional a scale value for x / y.
shilke2D = Shilke2D(320,240,60)
shilke2D:start()