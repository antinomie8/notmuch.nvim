local t = {}
local v = vim.api
local thread = require("notmuch.thread")
local u = require("notmuch.util")

local config = require("notmuch.config")

local function msg_call_method_on_tags(tags, method)
	local tags = vim.split(tags, "%s+", { trimempty = true })
	local db = require("notmuch.cnotmuch")(config.options.notmuch_db_path, 1)
	local id = thread.get_current_message_id()
	if id == nil then return end
	local msg = db.get_message(id)
	for i, tag in pairs(tags) do
		msg[method](msg, tag)
	end
	db.close()
end

function t.msg_add_tag(tags)
	msg_call_method_on_tags(tags, "add_tag")
end

function t.msg_rm_tag(tags)
	msg_call_method_on_tags(tags, "rm_tag")
end

function t.msg_toggle_tag(tags)
	msg_call_method_on_tags(tags, "toggle_tag")
end

local function thread_call_method_on_tags(tags, startlinenr, endlinenr, method)
	startlinenr = startlinenr or v.nvim_win_get_cursor(0)[1]
	endlinenr = endlinenr or startlinenr
	local tags = vim.split(tags, "%s+", { trimempty = true })
	local db = require("notmuch.cnotmuch")(config.options.notmuch_db_path, 1)
	for linenr = startlinenr, endlinenr do
		local line = vim.fn.getline(linenr)
		local threadid = string.match(line, "%S+", 8)
		local query = db.create_query("thread:" .. threadid)
		local thread = query.get_threads()[1]
		for i, tag in pairs(tags) do
			thread[method](thread, tag)
		end
	end
	db.close()
end

function t.thread_add_tag(tags, startlinenr, endlinenr)
	thread_call_method_on_tags(tags, startlinenr, endlinenr, "add_tag")
end

function t.thread_rm_tag(tags, startlinenr, endlinenr)
	thread_call_method_on_tags(tags, startlinenr, endlinenr, "rm_tag")
end

function t.thread_toggle_tag(tags, startlinenr, endlinenr)
	thread_call_method_on_tags(tags, startlinenr, endlinenr, "toggle_tag")
end

return t
