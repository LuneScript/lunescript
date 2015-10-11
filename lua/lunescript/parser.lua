local lpeg = lunescript.lpeg

local P, R, S, C, Cc, Ct, V = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.V

local white = S(" \t\r\n") ^ 0
local integer = R("09") ^ 1 / tonumber
local binOp = S("*+-/") + P("..")

-- might be shamelessly stolen from http://lua-users.org/wiki/LpegRecipes
local singlequoted_string = P "'" * C(((1 - S "'\r\n\f\\") + (P '\\' * 1)) ^ 0) * "'"
local doublequoted_string = P '"' * C(((1 - S '"\r\n\f\\') + (P '\\' * 1)) ^ 0) * '"'
local stringp = singlequoted_string + doublequoted_string

local function token(id, tokenKeys, p)
	if type(tokenKeys) ~= "table" then
		p = tokenKeys
		tokenKeys = {}
	end

	return p / function(...)
		local t = {id = id}
		for k,v in pairs{...} do
			t[tokenKeys[k]] = v
		end
		return t
	end
end

-- maps expression to a token
-- mostly exists to fix binops
local function exprMapper(...)
	local t = {...}
	if #t == 3 then
		return {id = "binOpExpr", left = t[1], op = t[2], right = t[3]}
	end
	return ...
end

local parser = P {
	"chunk",

	chunk = V("block") * (white ^ -1) * -1,
	block = Ct(V("stmt") ^ 0),

	stmt = white * (V("ifStmt") + V("varDeclStmt") + V("assignStmt") + V("expr")),
	varDeclStmt = token("varDeclStmt", {"type", "name", "expr"}, C(P("local") + P("var") + P("val")) * white * V("nameExpr") * (white * P("=") * white * V("expr"))^-1),
	assignStmt = token("assignStmt", {"name", "expr"}, V("nameExpr") * white * P("=") * white * V("expr")),
	ifStmt = token("ifStmt", {"cond", "block"}, P("if") * white * V("ifCond") * white * P("{") * V("block") * white * P("}")),

	expr = (V("value") * (white * C(binOp) * white * V("value"))^-1) / exprMapper,
	value = token("number", {"value"}, integer) + V("lambdaExpr") + V("callExpr") + V("nameExpr") + V("stringExpr"),

	callExpr = token("callExpr", {"name", "args"}, V("nameExpr") * white * P("(") * white * Ct(V("nameList")) * white * P(")")),
	nameExpr = token("nameExpr", {"value"}, R("AZ", "az", "09") ^ 1),
	stringExpr = token("stringExpr", {"value"}, stringp),

	lambdaExpr = token("lambdaExpr", {"params", "body"}, P("(") * white * Ct(V("nameList")) * white * P(")") * white * P("->") * white * V("lambdaBody")),
	lambdaBody = V("expr") + (P("{") * V("block") * white * P("}")),

	-- helpers
	nameList = (white * V("expr") * white * P(",")^-1)^0,

	-- special if condition
	ifCond = V("varDeclStmt") + V("expr")
}

lunescript.lpeg_parser = parser
