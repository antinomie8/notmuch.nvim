local d = {}

local function confirm_purge()
	-- Confirm
	vim.ui.select({ "Yes", "No" }, { prompt = "Purge deleted emails ?" }, function(choice)
		if choice == "Yes" then
			-- remove keymap
			vim.keymap.del("n", "DD", { buffer = true })

			-- search for mails to purge
			vim.system(
				{ "notmuch", "search", "--output=files", "--format=text0", "tag:del", "and", "tag:/./" },
				function(obj)
					-- purge deleted mails
					for _, file in ipairs(vim.split(obj.stdout, "\0", { plain = true })) do
						vim.uv.fs_unlink(file)
					end
					-- reindex mails
					vim.system({ "notmuch", "new" }, vim.schedule_wrap(
						require("notmuch.refresh").refresh_search_buffer
					))
				end
			)
		end
	end)
end

function d.purge_del()
	require("notmuch.notmuch").search_terms("tag:del and tag:/./")

	vim.keymap.set("n", "DD", function()
		confirm_purge()
	end, { buffer = true })
end

return d
