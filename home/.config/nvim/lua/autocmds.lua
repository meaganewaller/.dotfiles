vim.api.nvim_create_autocmd("FileType", {
	pattern = {"markdown", "text", "gitcommit"},
	callback = function()
		vim.opt_local.wrap = true
	end
})
