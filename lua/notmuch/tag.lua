local t = {}

local config = require("notmuch.config")

local function msg_call_method_on_tags(method, tags)
	local db = require("notmuch.cnotmuch")(config.options.notmuch_db_path, 1)
	local id = require("notmuch.thread").get_current_message_id()
	if id == nil then return end
	local msg = db.get_message(id)
	for i, tag in pairs(tags) do
		msg[method](msg, tag)
	end
	db.close()
end

---@param tags table<string>
function t.msg_add_tag(tags)
	msg_call_method_on_tags("add_tag", tags)
end

---@param tags table<string>
function t.msg_rm_tag(tags)
	msg_call_method_on_tags("rm_tag", tags)
end

---@param tags table<string>
function t.msg_toggle_tag(tags)
	msg_call_method_on_tags("toggle_tag", tags)
end

---@param tags table<string>
local function thread_call_method_on_tags(method, tags, startlinenr, endlinenr)
	startlinenr = startlinenr or vim.api.nvim_win_get_cursor(0)[1]
	endlinenr = endlinenr or startlinenr
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

---@param tags table<string>
function t.thread_add_tag(tags, startlinenr, endlinenr)
	thread_call_method_on_tags("add_tag", tags, startlinenr, endlinenr)
end

---@param tags table<string>
function t.thread_rm_tag(tags, startlinenr, endlinenr)
	thread_call_method_on_tags("rm_tag", tags, startlinenr, endlinenr)
end

---@param tags table<string>
function t.thread_toggle_tag(tags, startlinenr, endlinenr)
	thread_call_method_on_tags("toggle_tag", tags, startlinenr, endlinenr)
end

return t
