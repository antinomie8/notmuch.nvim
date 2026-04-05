vim.keymap.set("n", "q", function() require("notmuch.util").quit_or_bwipeout() end, { buffer = true })
vim.keymap.set("n", "v", function() require("notmuch.attach").view_attachment_part() end, { buffer = true })
vim.keymap.set("n", "o", function() require("notmuch.attach").open_attachment_part() end, { buffer = true })
vim.keymap.set("n", "s", function() require("notmuch.attach").save_attachment_part(nil, true) end, { buffer = true })
