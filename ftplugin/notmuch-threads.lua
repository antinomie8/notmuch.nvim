vim.opt_local.wrap = false

vim.api.nvim_buf_create_user_command(0, "DelThread", function(arg)
	local line1, line2 = arg.line1, arg.line2
	require("notmuch.tag").thread_add_tag({ "del" }, line1, line2)
	require("notmuch.tag").thread_rm_tag({ "inbox" }, line1, line2)
	require("notmuch.refresh").refresh_search_buffer()
end, {
	range = true,
})
vim.api.nvim_buf_create_user_command(0, "TagAdd", function(arg)
	require("notmuch.tag").thread_add_tag(arg.fargs, arg.line1, arg.line2)
end, {
	complete = require("notmuch.completion").comp_tags,
	range = true,
	nargs = "+",
})
vim.api.nvim_buf_create_user_command(0, "TagRm", function(arg)
	require("notmuch.tag").thread_rm_tag(arg.fargs, arg.line1, arg.line2)
end, {
	complete = require("notmuch.completion").comp_tags,
	range = true,
	nargs = "+",
})
vim.api.nvim_buf_create_user_command(0, "TagToggle", function(arg)
	require("notmuch.tag").thread_toggle_tag(arg.fargs, arg.line1, arg.line2)
end, {
	complete = require("notmuch.completion").comp_tags,
	nargs = "+",
})

vim.keymap.set("n", "<CR>", function() require("notmuch.notmuch").show_thread() end, { buffer = true })
vim.keymap.set("n", "r", function() require("notmuch.refresh").refresh_search_buffer() end, { buffer = true })
vim.keymap.set("n", "q", function() require("notmuch.util").quit_or_bwipeout() end, { buffer = true })
vim.keymap.set("n", "%", function() require("notmuch.sync").sync_maildir() end, { buffer = true })
vim.keymap.set("n", "C", function() require("notmuch.send").compose() end, { buffer = true })
vim.keymap.set("n", "D", function() require("notmuch.delete").purge_del() end, { buffer = true })
vim.keymap.set("n", "o", function() require("notmuch.notmuch").reverse_sort_threads() end, { buffer = true })

vim.keymap.set("n", "+", ":TagAdd<Space>", { buffer = true })
vim.keymap.set("x", "+", ":TagAdd<Space>", { buffer = true })
vim.keymap.set("n", "-", ":TagRm<Space>", { buffer = true })
vim.keymap.set("x", "-", ":TagRm<Space>", { buffer = true })
vim.keymap.set("n", "=", ":TagToggle<Space>", { buffer = true })
vim.keymap.set("x", "=", ":TagToggle<Space>", { buffer = true })

local keymaps = {
	{ key = "a", actions = { { "thread_toggle_tag", { "inbox" } } }, refresh = true },
	{ key = "A", actions = { { "thread_rm_tag", { "inbox", "unread" } } }, refresh = true },
	{ key = "x", actions = { { "thread_toggle_tag", { "unread" } } } },
	{ key = "f", actions = { { "thread_toggle_tag", { "flagged" } } } },
	{
		key = "dd",
		visual_key = "d",
		actions = {
			{ "thread_add_tag", { "del" } },
			{ "thread_rm_tag", { "inbox" } },
		},
		refresh = true,
	},
}
for _, keymap in ipairs(keymaps) do
	vim.keymap.set("n", keymap.key, function()
		for _, action in ipairs(keymap.actions) do
			require("notmuch.tag")[action[1]](action[2])
		end
		if keymap.refresh then
			require("notmuch.refresh").refresh_search_buffer()
		end
	end, { buffer = true })
	vim.keymap.set("x", keymap.visual_key or keymap.key, function()
		-- :h vim.keymap.set
		local region = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), {
			type = "v",
			exclusive = false,
			eol = false,
		})
		local start = region[1][1][2]
		local finish = region[#region][1][2]
		for _, action in ipairs(keymap.actions) do
			require("notmuch.tag")[action[1]](action[2], start, finish)
		end

		-- return to normal mode
		vim.api.nvim_feedkeys(
			vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
			"n",
			false
		)
		-- refresh
		if keymap.refresh then
			require("notmuch.refresh").refresh_search_buffer()
		end
	end, { buffer = true })
end
