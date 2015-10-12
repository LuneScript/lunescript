local lpeg = lunescript.lpeg

local P, R, S, C, Cc, Ct, V = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Cc, lpeg.Ct, lpeg.V

local parser_state = {}
local function update_parser_pos(t, pos)
	parser_state.pos = pos
	return pos
end

local whiteRaw = S(" \t\r\n") ^ 0
local whiteSync = whiteRaw * P(update_parser_pos)
local white = whiteSync

local comment = P("--") * (1 - S("\r\n\f")) ^ 0

local useless = comment^-1 * white

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

	stmt = useless * (V("ifStmt") + V("returnStmt") + V("varDeclStmt") + V("unpackStmt") + V("assignStmt") + V("blockStmt") + V("expr")),

	varDeclStmt = token("varDeclStmt", {"type", "name", "expr"}, C(P("local") + P("var") + P("val")) * white * V("nameExpr") * (white * P("=") * white * V("expr"))^-1),
	unpackStmt = token("unpackStmt", {"identifiers", "expr"}, P("val") * white * P("{") * white * Ct(V("nameList")) * white * P("}") * white * P("=") * white * V("expr")),

	assignStmt = token("assignStmt", {"name", "expr"}, V("nameExpr") * white * P("=") * white * V("expr")),
	ifStmt = token("ifStmt", {"cond", "block"}, P("if") * white * V("ifCond") * white * V("blockStmt")),
	blockStmt = token("blockStmt", {"statements"}, P("{") * V("block") * white * P("}")),
	returnStmt = token("returnStmt", {"expr"}, P("return") * white * V("expr")),

	expr = (V("value") * (white * C(binOp) * white * V("value"))^-1) / exprMapper,
	value = token("number", {"value"}, integer) + V("lambdaExpr") + V("callExpr") + V("nameExpr") + V("stringExpr"),

	callExpr = token("callExpr", {"name", "args"}, V("nameExpr") * white * P("(") * white * Ct(V("argList")) * white * P(")")),
	nameExpr = token("nameExpr", {"value"}, R("AZ", "az", "09") ^ 1),
	stringExpr = token("stringExpr", {"value"}, stringp),

	lambdaExpr = token("lambdaExpr", {"params", "body"}, P("(") * white * Ct(V("nameList")) * white * P(")") * white * P("->") * white * V("lambdaBody")),
	lambdaBody = V("expr") + V("blockStmt"),

	-- helpers
	nameList = (white * V("nameExpr") * white * P(",")^-1)^0,
	argList = (white * V("expr") * white * P(",")^-1)^0,

	-- special if condition
	ifCond = V("varDeclStmt") + V("expr")
}

function lunescript.parse(code)
	parser_state.pos = 0
	local t, si, caps = parser:match(code)
	if t then return t end

	local endpos = parser_state.pos or 0

	local row, col = 0, 0

	local nlChar = string.byte("\n")
	for i=1, endpos do
		col = col+1
		if string.byte(code, i) == nlChar then
			row = row+1
			col = 0
		end
	end

	return false, "Syntax error on line " .. row .. " col " .. col
end
