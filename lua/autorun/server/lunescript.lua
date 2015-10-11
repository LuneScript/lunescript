include("lunescript/lunescript.lua")

for _,fil in pairs(file.Find("autorun/server/*.lune", "LUA")) do
	local contents = file.Read("autorun/server/" .. fil, "LUA")
	local lua = lunescript.compile_lune_to_lua(contents)

	RunStringEx(lua, "lua/autorun/server/" .. fil)
end
