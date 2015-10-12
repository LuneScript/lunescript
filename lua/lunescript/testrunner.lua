local test_fn_meta = {}
test_fn_meta.__index = test_fn_meta

function test_fn_meta:expectReturn(res)
	self.expectedRet = {res}
end

local function comp(t1, t2)
	if table.Count(t1) ~= table.Count(t2) then return false end
	for k,v in pairs(t1) do
		if v ~= t2[k] then return false end
	end
	return true
end
function test_fn_meta:test(returns)
	if self.expectedRet and not comp(returns, self.expectedRet) then
		error("Failed assertion: returns match")
	end
end

function lunescript.run_tests()
	local test_env = setmetatable({}, {__index = _G})
	function test_env.run(code, env, fn)
		local compiled = CompileString(lunescript.compile_lune_to_lua(code), "lunescript test compile")
		setfenv(compiled, env or _G)

		local asserts = setmetatable({}, test_fn_meta)
		fn(asserts)

		local ret = {compiled()}
		asserts:test(ret)
	end

	for _,fil in pairs(file.Find("lunescript/tests/*.lua", "LUA")) do
		local testmod = CompileString(file.Read("lunescript/tests/" .. fil, "LUA"), "lunescript test " .. fil)
		setfenv(testmod, test_env)
		testmod()
	end

	print("LuneScript tests succeeded")
end
