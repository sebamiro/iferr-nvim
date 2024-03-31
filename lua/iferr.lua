local ls = require("luasnip")

local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

local s = ls.snippet
local c = ls.choice_node
local d = ls.dynamic_node
local i = ls.insert_node
local t = ls.text_node
local sn = ls.snippet_node

local function get_function_parent(node)
	local func_types = {
		func_literal = true,
		function_declaration = true,
		method_declaration = true
	}

	if not node or func_types[node:type()] then
		return node
	end
	return get_function_parent(node:parent())
end

local zero_values = {
	int = "0",
	bool = "false",
	string = '""',

	error = function(_, info)
		if info then
			info.index = info.index + 1

			return c(info.index, {
				t(info.err_name),
				t(string.format('errors.Wrap(%s, "%s")', info.err_name, info.func_name)),
			})
		else
			return t("err")
		end
	end,

	[function(text)
		return string.find(text, "*", 1, true) ~= nil
	end] = function(_, _)
		return t("nil")
	end,

	[function(text)
		return text:match("%u")
	end] = function(text, info)
		info.index = info.index + 1

		return c(info.index, {
			t(text .. "{}"),
			t(text)
		})
	end,
}

local transform = function(text, info)
	local condition_matches = function(condition, ...)
		if type(condition) == "string" then
			return condition == text
		else
			return condition(...)
		end
	end

	for condition, result in pairs(zero_values) do
		if condition_matches(condition, text, info) then
			if type(result) == "string" then
				return t(result)
			else
				return result(text, info)
			end
		end
	end

	return t(text)
end

local handlers = {
	parameter_list = function(node, info)
		local params = {}
		local count = node:named_child_count()

		for idx = 0, count - 1 do
			local children = node:named_child(idx)
			local type_node = children:field("type")[1]
			table.insert(params, transform(vim.treesitter.get_node_text(type_node, 0), info))
			if idx ~= count - 1 then
				table.insert(params, t { ", " } )
			end
		end
		return params
	end,

	type_identifier = function(node, info)
		local text = vim.treesitter.get_node_text(node, 0)
		return { transform(text, info) }
	end
}

local function get_result_value(info)
	local func_node = get_function_parent(vim.treesitter.get_node())
	if not func_node then
		vim.notify("Not in a function")
		return t("Error")
	end
	local result = func_node:field("result")[1]
	if result then
		if handlers[result:type()] then
			return handlers[result:type()](result, info)
		end
	end
	return t("")
end

local function iferr(args)
	return sn(nil,
		get_result_value({
			index = 0,
			err_name = args[1][1],
			func_name = args[2][1],
		})
	)
end

local function setup()
	ls.add_snippets("go", {
		s(
			"efi",
			fmta(
				[[
		<val>, <err> := <f>(<args>)
		if <err_same> != nil {
			return <result>
		}
		<finish>
		]],
				{
					val = i(1),
					err = i(2, "err"),
					f = i(3),
					args = i(4),
					err_same = rep(2),
					result = d(5, iferr, { 2, 3 }),
					finish = i(0),
				}
			)
		),
	})
end

return {
	setup = setup,
}
