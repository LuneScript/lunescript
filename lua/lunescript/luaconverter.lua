-- converts parsed AST to Lua

function lunescript.to_lua(ast)
	local t = {}

	local indLevel = 0
	local function ind(delta) indLevel = indLevel+delta end
	local function indStr()
		local t = {} for i=1, indLevel do t[i] = "   " end return table.concat(t, "")
	end
	local function push(s, ...)
		table.insert(t, string.format(indStr() .. s, ...))
	end

	local block, expr, stmt

	function expr(n)
		if n.id == "nameExpr" or n.id == "number" then
			return n.value
		elseif n.id == "stringExpr" then
			return string.format("%q", n.value)
		elseif n.id == "callExpr" then
			local mappedArgs = {}
			for k,v in pairs(n.args or {}) do mappedArgs[k] = expr(v) end
			return string.format("%s(%s)", expr(n.name), table.concat(mappedArgs, ", "))
		elseif n.id == "lambdaExpr" then
			local mappedArgs = {}
			for k,v in pairs(n.params or {}) do mappedArgs[k] = expr(v) end

			local code
			if n.body.id then
				-- single expr
				code = "return " .. expr(n.body)
			else
				local codet = {}
				block(n.body, function(t) table.insert(codet, t) end, function() end)
				code = table.concat(codet, " ")
			end

			return string.format("function(%s) %s end", table.concat(mappedArgs, ", "), code)
		elseif n.id == "binOpExpr" then
			return string.format("%s %s %s", expr(n.left), n.op, expr(n.right))
		end
		return "- '" .. n.id .. "'not implemented-"
	end

	function stmt(n, _push, _ind)
		local push, ind = _push or push, _ind or ind

		if n.id == "varDeclStmt" then
			push("%s %s = %s", "local", expr(n.name), expr(n.expr))
		elseif n.id == "assignStmt" then
			push("%s = %s", expr(n.name), expr(n.expr))
		elseif n.id == "ifStmt" then
			local ifCond = n.cond

			local isVarDecl = n.cond.id == "varDeclStmt"
			local origName
			if isVarDecl then
				origName = n.cond.name.value

				local randVar = "_tmp_" .. origName
				n.cond.name.value = randVar

				stmt(n.cond)
				ifCond = n.cond.name
			end

			push("if %s then", expr(ifCond)) ind(1)

			if isVarDecl then stmt{id = "varDeclStmt", type = n.cond.type, name = {id = "nameExpr", value = origName}, expr = {id = "nameExpr", value = n.cond.name.value}} end

			block(n.block)
			ind(-1) push("end")
		else
			push(expr(n))
		end
	end
	function block(n, _push, _ind)
		local push, ind = _push or push, _ind or ind

		for _,v in pairs(n) do
			stmt(v, push, ind)
		end
	end
	block(ast)

	return table.concat(t, "\n")
end
