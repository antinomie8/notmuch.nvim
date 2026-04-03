local config = {}

---@return NotmuchConfig?
local function get_defaults()
	---@param key string config key to ask notmuch for
	local function get_notmuch_config(key)
		local handler = vim.system({ "notmuch", "config", "get", key }):wait()
		if handler.code ~= 0 then
			if not vim.fn.executable("notmuch") then
				vim.notify("notmuch command not found. Please install notmuch.", vim.log.levels.ERROR)
			end
		else
			return vim.trim(handler.stdout) -- remove trailing '\n'
		end
	end

	local name = get_notmuch_config("user.name")
	local email = get_notmuch_config("user.primary_email")
	local db_path = get_notmuch_config("database.path")

	-- Validate required configuration form notmuch and fail-fast
	if not db_path then
		vim.notify(
			"notmuch.nvim: database.path not configured.\n" ..
			"Please run: notmuch setup",
			vim.log.levels.ERROR
		)
		return
	end

	-- Validate user name and email from notmuch config
	if not name or not email then
		vim.notify(
			"notmuch.nvim: user.name or user.primary_email not configured.\n" ..
			"Please run: notmuch setup",
			vim.log.levels.WARN
		)
		name = name or "User"
		email = email or "user@localhost"
	end

	---@class NotmuchConfig
	local defaults = {
		notmuch_db_path = db_path,
		from = name .. " <" .. email .. ">",
		maildir_sync_cmd = "mbsync -a",
		open_cmd = "xdg-open",
		logfile = nil,
		sync = {
			sync_mode = "buffer",  -- "background" | "buffer" | "terminal"
			--   background: Silent sync in background, notifications only
			--   buffer: Structured async output in dedicated buffer, no stdin (default)
			--   terminal: Real PTY terminal with stdin support for GPG/OAuth prompts
		},
		suppress_deprecation_warning = false, -- Used for API deprecation warning suppression
		render_html_body = false, -- True means prioritize displaying rendered HTML
		open_handler = function(attachment)
			require("notmuch.handlers").default_open_handler(attachment)
		end,
		view_handlers = {},
		view_handler = function(attachment)
			return require("notmuch.handlers").default_view_handler(attachment)
		end,
		keymaps = { -- This should capture all notmuch.nvim related keymappings
			sendmail = "<C-g><C-g>",
			attachment_window = "<C-g><C-a>",
		},
	}
	return defaults
end

---@param opts NotmuchConfig user configuration
---@return boolean success wether the configuration loading succeeded
config.setup = function(opts)
	local options = opts or {}
	local defaults = get_defaults()

	if not defaults then
		vim.notify(
			"notmuch.nvim: Failed to load. Please configure notmuch first.",
			vim.log.levels.ERROR
		)
		return false
	end

	-- If `notmuch_db_path` is set by user, expand it in case of tildes, etc.
	if opts.notmuch_db_path then
		options.notmuch_db_path = vim.fn.expand(options.notmuch_db_path)
	end

	config.options = vim.tbl_deep_extend("force", defaults, options)
	return true
end

return config
