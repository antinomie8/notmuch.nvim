-- welcome screen displaying all tags available to search
local keymaps = {
  { "<CR>", function() require("notmuch.notmuch").search_terms("tag:" .. vim.api.nvim_get_current_line()) end},
  { "c",    function() require("notmuch.notmuch").count("tag:" .. vim.api.nvim_get_current_line()) end},
  { "q",    function() require("notmuch.util").quit_or_bwipeout() end},
  { "r",    function() require("notmuch.refresh").refresh_hello_buffer() end},
  { "C",    function() require("notmuch.send").compose() end},
  { "%",    function() require("notmuch.sync").sync_maildir() end},
}
for _, keymap in ipairs(keymaps) do
  vim.keymap.set("n", keymap[1], keymap[2], { buffer = true })
end
