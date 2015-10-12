run("val simple = () -> 'hello world' return simple()", _G, function(test)
	test:expectReturn("hello world")
end)
