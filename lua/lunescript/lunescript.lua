lunescript = {}

-- this is kind of awkward lol, TODO
lunescript.lpeg = CompileString(file.Read("lunescript/lulpeg.lua", "LUA"), "lulpeg")()

include("parser.lua")
include("luaconverter.lua")
include("testrunner.lua")

function lunescript.compile_ast(str)
	local ast, msg = lunescript.parse(str)
	if not ast then
		error("LuneScript parser failed: " .. msg)
	end
	return ast
end
function lunescript.compile_lune_to_lua(str)
	return lunescript.to_lua(lunescript.compile_ast(str))
end
function lunescript.run(str)
	RunString(lunescript.compile_lune_to_lua(str))
end
function lunescript.rund(str)
	local ast = lunescript.compile_ast(str)
	print("Created AST:")
	PrintTable(ast)
	print("Created Lua:")
	local lua = lunescript.to_lua(ast)
	print(lua)

	RunString(lua)
end
