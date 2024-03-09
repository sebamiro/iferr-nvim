local api = vim.api

-- TSNode:type() string
-- TSNode:iter_children()
-- TSNode:field()

local function get_function_parent(c_node)
	if c_node:type() == "func_literal" or c_node:type() == "function_declaration" then
		return c_node
	end
	return get_function_parent(c_node:parent())
end

local function get_result_type(func_node)
	local count = func_node:child_count()
	local type = func_node:type() == "func_literal"
	if (type and count <= 3) or (not type and count <= 4) then
		return nil
	end
	return "Hola"
end

local function get_return_value()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local func_node = get_function_parent(ts_utils.get_node_at_cursor(0))
	print(get_result_type(func_node))
	return "err"
end

local function iferr()
	local row = api.nvim_win_get_cursor(0)[1]
	local line = api.nvim_get_current_line()
	local ident = line:sub(0, line:find("%S", 0, false) - 1)
	api.nvim_buf_set_lines(0, row, row, false, {
		ident .. "if err != nil {",
		ident .. "\treturn " .. get_return_value(),
		ident .. "}"
	})
	api.nvim_win_set_cursor(0, {row + 3, ident:len()})
end

return {
	iferr = iferr
}
