if vim.startswith(vim.fs.basename(vim.api.nvim_buf_get_name(0)), "thread:") then
	vim.opt_local.foldmethod = "marker"
	vim.opt_local.foldlevel = 0

	-- open folds if there is only a single message
	if vim.b.notmuch_messages and #vim.b.notmuch_messages == 1 then
		vim.schedule(function()
			vim.cmd.normal({ args = { "zR" }, bang = true })
		end)
	end

	vim.api.nvim_buf_create_user_command(0, "TagAdd", function(arg)
		require("notmuch.tag").thread_add_tag(arg.fargs)
	end, {
		complete = require("notmuch.completion").comp_tags,
		nargs = "+",
	})
	vim.api.nvim_buf_create_user_command(0, "TagRm", function(arg)
		require("notmuch.tag").thread_rm_tag(arg.fargs)
	end, {
		complete = require("notmuch.completion").comp_tags,
		nargs = "+",
	})
	vim.api.nvim_buf_create_user_command(0, "TagToggle", function(arg)
		require("notmuch.tag").thread_toggle_tag(arg.fargs)
	end, {
		complete = require("notmuch.completion").comp_tags,
		nargs = "+",
	})
	vim.api.nvim_buf_create_user_command(0, "FollowPatch", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		require("notmuch.attach").follow_github_patch(line)
	end, {})

	vim.keymap.set("n", "U", function() require("notmuch.attach").get_urls_from_cursor_msg() end, { buffer = true })
	vim.keymap.set("n", "a", function() require("notmuch.attach").get_attachments_from_cursor_msg() end, { buffer = true })
	vim.keymap.set("n", "r", function() require("notmuch.refresh").refresh_thread_buffer() end, { buffer = true })
	vim.keymap.set("n", "C", function() require("notmuch.send").compose() end, { buffer = true })
	vim.keymap.set("n", "R", function() require("notmuch.send").reply() end, { buffer = true })
	vim.keymap.set("n", "q", function() require("notmuch.util").quit_or_bwipeout() end, { buffer = true })

	vim.keymap.set("n", "+", ":TagAdd<Space>", { buffer = true })
	vim.keymap.set("n", "-", ":TagRm<Space>", { buffer = true })
	vim.keymap.set("n", "=", ":TagToggle<Space>", { buffer = true })

	vim.keymap.set("n", "<Tab>", "zj", { buffer = true, silent = true })
	vim.keymap.set("n", "<S-Tab>", "zk", { buffer = true, silent = true })
	vim.keymap.set("n", "<Enter>", "za", { buffer = true, silent = true })
end
