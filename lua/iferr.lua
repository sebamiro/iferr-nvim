local api = vim.api

local function get_function_parent(node)
	if node:type():match("func_literal")
		or node:type():match("function_declaration")
		or node:type():match("method_declaration") then
		return node
	end
	return get_function_parent(node:parent())
end

local function get_zero_value(node)
	if node:type() == "pointer_type" then
		return "nil"
	end
	local row, scol, _ = node:start()
	local _, ecol, _ = node:end_()
	local type = api.nvim_buf_get_text(0, row, scol, row, ecol, {})[1]
	if type == "error" then
		return "err"
	elseif type == "string" then
		return '""'
	elseif type:sub(0, 3):match("int") or type:sub(0, 5):match("float") or type:sub(0, 4):match("uint") then
		return "0"
	elseif type:sub(0, 1):match("%u") then
		return type .. "{}"
	end
	return type
end

local function get_parameter_list_value(node)
	local params = {}
	for c in node:iter_children() do
		if c:type():match("parameter_declaration") then
			table.insert(params, get_zero_value(c:child(0)))
		end
	end
	return table.concat(params, ", ")
end

local function get_result_type(func_node)
	local result = func_node:field("result")[1]
	if result:type():match("parameter_list") then
		return get_parameter_list_value(result)
	end
	return get_zero_value(result)
end

local function get_return_value()
	local func_node = get_function_parent(require("nvim-treesitter.ts_utils").get_node_at_cursor(0))
	local count = func_node:child_count()
	local type = func_node:type():match("func_literal")
	if (type and count <= 3) or (not type and count <= 4) then
		return ""
	end
	return " " .. get_result_type(func_node)
end

local function iferr()
	local row = api.nvim_win_get_cursor(0)[1]
	local line = api.nvim_get_current_line()
	local ident = line:sub(0, line:find("%S", 0, false) - 1)
	api.nvim_buf_set_lines(0, row, row, false, {
		ident .. "if err != nil {",
		ident .. "\treturn" .. get_return_value(),
		ident .. "}"
	})
	api.nvim_win_set_cursor(0, { row + 3, ident:len() })
end

return {
	iferr = iferr
}
