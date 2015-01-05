--[[---
Json module allows to encode/decode tables to/from json.

The encode and decode functions works with strings, but deafult file handling functions
are provided (for load / save)

Infinite loops are not handled, so a table containing a reference to itself cannot be encoded.

Shilke2D can rely on MOAI native C++ implementation or on the lua json parser created by
Shaun Brown. The used parser is configured using the <b>__USE_LUAJSONPARSER__</b> include 
option.

Results are not exactly the same, in particular float are encoded slightly differently 
(approximation differences). Decoding an encoded float anyway gives always the same result.

Notes:

<ul>
	<li>Encodable Lua types: string, number, boolean, table, nil</li>
	<li>Non Encodable Lua types: function, thread, userdata</li>
	<li>All control chars are encoded to \uXXXX format eg "\021" encodes to "\u0015"</li>
	<li>All Json \uXXXX chars are decoded to chars (0-255 byte range only)</li>
	<li>Json single line // and /* */ block comments are discarded during decoding</li>
	<li>Numerically indexed Lua arrays are encoded to Json Lists eg [1,2,3]</li>
	<li>Lua dictionary tables are converted to Json objects eg {"one":1,"two":2}</li>
</ul>

@usage

 -- Lua script:
 local t = { 
    ["name1"] = "value1",
    ["name2"] = {1, false, true, 23.54, "a \021 string"},
    name3 = nil 
 }

 local json = Json.encode(t)
 print(json) 
 --> {"name1":"value1","name3":null,"name2":[1,false,true,23.54,"a \u0015 string"]}

 local t = Json.decode(json)
 print(t.name2[4])
 --> 23.54
 
-- wrong usage: 
t = {}
t["test"] = t

Json.encode(t)
--> inifinite callstack resulting in a crash
 
--]]

if __USE_LUAJSONPARSER__ then
	--use lua parser implementation, where Json namespace and Json.encode/decode are already defined 
	require("Shilke2D/Utils/Config/Externals/JsonParser")
else
	--define Json namespace and remap MOAIJsonParser.encode/decode over Json.encode/decode
	Json = {}
	
	--[[---
	Encodes a lua table into a json string
	@function Json.encode
	@tparam table t the lua table to encode
	@treturn string the encoded json string
	--]]
	Json.encode = MOAIJsonParser.encode
	
	--[[---
	Decodes a json string converting into a lua object
	@function Json.decode
	@tparam string s the json string to decode
	@treturn table a lua object
	--]]
	Json.decode = MOAIJsonParser.decode
end


--[[---
Reads a json text file and returns the decoded lua table
@tparam string fileName name of the file to parse
@treturn[1] table a lua table rapresenting decoded json file
@return[2] nil
@treturn[2] string error message if decoding/read failed
--]]
function Json.readFile(fileName)
	local json, res = IO.getFile(fileName)
	if not json then
		return nil, res
	end
	return Json.decode(json)
end

--[[---
Encodes an object and saves the resulting string on a file
@tparam table t the lua table to encode
@string fileName the name of the file to save the encoded object
@treturn[1] bool success
@return[2] nil
@treturn[2] string error message if encoding/save failed
--]]
function Json.saveFile(t, fileName)
	local file, err = IO.open(fileName,'w')
	if not file then
		return false, err
	end
	file:write(Json.encode(t))
	io.close(file)
	return true
end
