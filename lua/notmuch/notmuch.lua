local nm = {}

local config = require("notmuch.config")

-- Launch `notmuch.nvim` landing page
--
-- This function launches the main entry point of the plugin into your notmuch
-- database. You are greeted with a list of all the tags in your database,
-- available for querying and/or counting. First line contains help hints.
--
-- If buffer is already open from before, it will simply load it as active
--
---@usage lua require('notmuch').notmuch_hello()
nm.notmuch_hello = function()
	local bufno = vim.fn.bufnr("Tags")
	if bufno ~= -1 then
		vim.api.nvim_win_set_buf(0, bufno)
	else
		nm.show_all_tags() -- Move to tag.lua
	end
	print("Welcome to Notmuch.nvim! Choose a tag to search it.")
end

---Conducts a `notmuch search` operation
--
---This function takes a search term, runs the query against your notmuch
---database asynchronously and returns the list of thread results in a
---buffer for the user to browse
---
---```lua
---require('notmuch').search_terms('tag:inbox')
---```
---
---@param search string search terms matching format from `notmuch-search-terms(7)`
---@param jumptothreadid string? jump to thread id after search
function nm.search_terms(search, jumptothreadid)
	if search == "" then
		return
	elseif string.match(search, "^thread:%S+$") ~= nil then
		nm.show_thread(search)
		return
	end
	-- Use exact match for buffer name to avoid partial matches
	-- Escape special regex characters in the search term
	local buf
	local escaped_search = vim.fn.escape(search, "^$.*~[]\\")
	local bufno = vim.fn.bufnr("^" .. escaped_search .. "$")
	if bufno ~= -1 then
		vim.api.nvim_win_set_buf(0, bufno)
		buf = bufno
	else
		buf = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_buf_set_name(buf, search)
		vim.api.nvim_win_set_buf(0, buf)
	end

	local hint_text = "Hints: <Enter>: Open thread | q: Close | r: Refresh | " ..
	                  "%: Sync maildir | a: Archive | A: Archive and Read | " ..
	                  "+/-/=: Add, remove, toggle tag | o: Sort | dd: Delete"
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, 2, false, { hint_text, "" })

	require("notmuch.async").run_notmuch_search(search, { buf = buf, lbegin = 1 }, function()
		-- Check if buffer is still valid (might have been deleted during refresh)
		if not vim.api.nvim_buf_is_valid(buf) then return end
		-- restore cursor position
		if jumptothreadid then
			vim.fn.search(jumptothreadid)
		end
	end)

	-- remove tail
	vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})
	-- set options
	vim.bo.filetype = "notmuch-threads"
	vim.bo.modifiable = false
end

--- Reverses the threads sorting in `notmuch-threads` buffer
--
-- This function reverses the lines of the `notmuch-threads` buffer which result
-- from the `search_terms()` function. It effectively toggles the sorting of
-- these threads between newest-first and oldest-first.
--
-- We do this instantly instead of running `notmuch search --sort` to save time
-- especially when it comes to large results with thousands of thread.
nm.reverse_sort_threads = function()
	-- Get all lines, disregarding top-level hints line
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local hints = table.remove(lines, 1)

	-- Reverse lines
	local reversed = {}
	for i = #lines, 1, -1 do
		table.insert(reversed, lines[i])
	end

	-- Re-attach hints line
	table.insert(reversed, 1, hints)

	-- Replace lines in buffer
	vim.bo.modifiable = true
	vim.api.nvim_buf_set_lines(0, 0, -1, false, reversed)
	vim.bo.modifiable = false
end

--- Opens a thread in the mail view with all messages in the thread
--
-- This function fetches all the messages in the input thread's ID from the
-- notmuch database and displays them in the mail.vim view.
--
---@param s string: The string to fetch the threadid from (individual line, or
--                  thread full form)
---@return true|nil: `true` for successful display, nil for any error
--
---@usage
-- nm.show_thread("thread:00000000000003aa")
-- nm.show_thread(vim.api.nvim_get_current_line())
nm.show_thread = function(s)
	-- Fetch the threadid from the input `s` or from current line
	local threadid = ""
	if s == nil then
		-- fetch from the current line since no input passed
		local line = vim.api.nvim_get_current_line()
		if line:find("Hints:") == 1 then
			-- Skip if selected the Hints line
			print("Cannot open Hints :-)")
			return nil
		end
		threadid = string.match(line, "[0-9a-z]+", 7)
	else
		threadid = string.match(s, "[0-9a-z]+", 7)
	end

	-- Open buffer if already exists, otherwise create new `buf`
	local bufno = vim.fn.bufnr("thread:" .. threadid)
	if bufno ~= -1 then
		vim.api.nvim_win_set_buf(0, bufno)
		return true
	end
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, "thread:" .. threadid)
	vim.api.nvim_win_set_buf(0, buf)

	-- Get output (JSON parsed) and display lines in buffer
	local lines, metadata = require("notmuch.thread").show_thread(threadid)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Set up buffer-local variables with thread metadata
	vim.b.notmuch_thread = metadata.thread
	vim.b.notmuch_messages = metadata.messages

	-- Insert hint message at the top of the buffer
	local hint_text =
	"Hints: <Enter>: Toggle fold message | <Tab>: Next message | <S-Tab>: Prev message | q: Close | a: See attachment parts"
	vim.api.nvim_buf_set_lines(buf, 0, 0, false, { hint_text, "" })

	-- Place cursor at head of buffer and prepare display and disable modification
	vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.bo.filetype = "mail"
	vim.bo.modifiable = false

	-- Set up cursor tracking for updating vim.b.notmuch_current
	require("notmuch.thread").setup_cursor_tracking(buf)
end

-- Counts the number of threads matching the search terms
--
-- This function runs a search query in your `notmuch` database against the
-- argument search terms and returns the number of threads which match
--
---@param search string: search terms matching format from
--                       `notmuch-search-terms(7)`
--
---@usage
-- lua require('notmuch').count('tag:inbox') -- > '999'
nm.count = function(search)
	local db = require("notmuch.cnotmuch")(config.options.notmuch_db_path, 0)
	local q = db.create_query(search)
	local count_threads = q.count_threads()
	db.close()
	return "[" .. search .. "]: " .. count_threads .. " threads"
end

--- Opens the landing/homepage for Notmuch: the `hello` page
--
-- This function opens the main landing page for `notmuch.nvim`. It essentially
-- consists of all the tags in the `notmuch` database for the user to select or
-- count. They can also search from here etc.
--
---@usage
-- nm.show_all_tags() -- opens the `hello` page
nm.show_all_tags = function()
	-- Fetch all tags available in the notmuch database
	local db = require("notmuch.cnotmuch")(config.options.notmuch_db_path, 0)
	local tags = db.get_all_tags()
	db.close()

	-- Create dedicated buffer. Content is fetched using `db.get_all_tags()`
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_buf_set_name(buf, "Tags")
	vim.api.nvim_win_set_buf(0, buf)
	vim.api.nvim_buf_set_lines(buf, 0, 0, true, tags)

	-- Insert help hints at the top of the buffer
	local hint_text = "Hints: <Enter>: Show threads | q: Close | r: Refresh | %: Refresh maildir | c: Count messages"
	vim.api.nvim_buf_set_lines(buf, 0, 0, false, { hint_text, "" })

	-- Clean up the buffer and set the cursor to the head
	vim.api.nvim_win_set_cursor(0, { 3, 0 })
	vim.api.nvim_buf_set_lines(buf, -2, -1, true, {})
	vim.bo.filetype = "notmuch-hello"
	vim.bo.modifiable = false
end

return nm
