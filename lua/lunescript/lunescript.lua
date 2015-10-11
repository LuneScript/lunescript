lunescript = {}

-- this is kind of awkward lol, TODO
lunescript.lpeg = CompileString(file.Read("lunescript/lulpeg.lua", "LUA"), "lulpeg")()

include("parser.lua")
include("luaconverter.lua")

function lunescript.compile_lune_to_lua(str)
	local ast = lunescript.lpeg_parser:match(str)
	local lua = lunescript.to_lua(ast)
	return lua
end
function lunescript.run(str)
	RunString(lunescript.compile_lune_to_lua(str))
end
