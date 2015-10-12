run("val {debug, getinfo} = debug return getinfo", _G, function(test)
	test:expectReturn(debug.getinfo)
end)
