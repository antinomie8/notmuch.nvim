vim.opt_local.wrap = false

vim.api.nvim_buf_create_user_command(0, "DelThread", function(arg)
  local line1, line2 = arg.line1, arg.line2
  require("notmuch.tag").thread_add_tag("del", line1, line2)
  require("notmuch.tag").thread_rm_tag("inbox", line1, line2)
  vim.opt_local.modifiable = true
  vim.api.nvim_buf_set_lines(0, math.min(line1, line2) - 1, math.max(line1, line2), true, {})
  vim.opt_local.modifiable = false
end, {
  range = true,
})
vim.api.nvim_buf_create_user_command(0, "TagAdd", function(arg)
  require("notmuch.tag").thread_add_tag(arg.args, arg.line1, arg.line2)
end, {
  complete = require("notmuch.completion").comp_tags,
  range = true,
  nargs = "+",
})
vim.api.nvim_buf_create_user_command(0, "TagRm", function(arg)
  require("notmuch.tag").thread_rm_tag(arg.args, arg.line1, arg.line2)
end, {
  complete = require("notmuch.completion").comp_tags,
  range = true,
  nargs = "+",
})

vim.keymap.set("n", "<CR>", function() require("notmuch.notmuch").show_thread() end, { buffer = true })
vim.keymap.set("n", "r", function() require("notmuch.refresh").refresh_search_buffer() end, { buffer = true })
vim.keymap.set("n", "q", function() require("notmuch.util").quit_or_bwipeout() end, { buffer = true })
vim.keymap.set("n", "%", function() require("notmuch.sync").sync_maildir() end, { buffer = true })
vim.keymap.set("n", "C", function() require("notmuch.send").compose() end, { buffer = true })
vim.keymap.set("n", "+", ":TagAdd<Space>", { buffer = true })
vim.keymap.set("x", "+", ":TagAdd<Space>", { buffer = true })
vim.keymap.set("n", "-", ":TagRm<Space>", { buffer = true })
vim.keymap.set("x", "-", ":TagRm<Space>", { buffer = true })
vim.keymap.set("n", "=", ":TagToggle<Space>", { buffer = true })
vim.keymap.set("x", "=", ":TagToggle<Space>", { buffer = true })
vim.keymap.set("n", "a", "<Cmd>TagToggle inbox<CR>j", { buffer = true })
vim.keymap.set("x", "a", ":TagToggle inbox<CR>", { buffer = true })
vim.keymap.set("n", "A", "<Cmd>TagRm inbox unread<CR>j", { buffer = true })
vim.keymap.set("x", "A", ":TagRm inbox unread<CR>", { buffer = true })
vim.keymap.set("n", "x", "<Cmd>TagToggle unread<CR>", { buffer = true })
vim.keymap.set("x", "x", ":TagToggle unread<CR>", { buffer = true })
vim.keymap.set("n", "f", "<Cmd>TagToggle flagged<CR>j", { buffer = true })
vim.keymap.set("x", "f", ":TagToggle flagged<CR>", { buffer = true })
vim.keymap.set("n", "dd", "<Cmd>DelThread<CR>", { buffer = true })
vim.keymap.set("x", "d", ":DelThread<CR>", { buffer = true })
vim.keymap.set("n", "D", function() require("notmuch.delete").purge_del() end, { buffer = true })
vim.keymap.set("n", "o", function() require("notmuch.notmuch").reverse_sort_threads() end, { buffer = true })
