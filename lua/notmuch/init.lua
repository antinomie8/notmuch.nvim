local M = {}

local config = require("notmuch.config")

---@param opts table: Table of options as passed by the user with their config setup
M.setup = function(opts)
	local success = config.setup(opts)

	if not success then
		return
	end

	-- setup user commands
	vim.api.nvim_create_user_command("Notmuch", function()
		require("notmuch.notmuch").notmuch_hello()
	end, { desc = "notmuch.nvim landing page" })
	vim.api.nvim_create_user_command("Inbox", function(arg)
		if #arg.fargs ~= 0 then
			require("notmuch.notmuch").search_terms("tag:inbox to:" .. arg.args)
		else
			require("notmuch.notmuch").search_terms("tag:inbox")
		end
	end, {
		desc = "Open inbox",
		nargs = "?",
		complete = require("notmuch.completion").comp_address,
	})
	vim.api.nvim_create_user_command("NmSearch", function(arg)
		require("notmuch.notmuch").search_terms(arg.args)
	end, {
		desc = "Notmuch search",
		nargs = "*",
		complete = require("notmuch.completion").comp_search_terms,
	})
	vim.api.nvim_create_user_command("ComposeMail", function(arg)
		require("notmuch.send").compose(arg.args)
	end, {
		desc = "Compose mail",
		nargs = "*",
		complete = require("notmuch.completion").comp_address,
	})
end

return M
