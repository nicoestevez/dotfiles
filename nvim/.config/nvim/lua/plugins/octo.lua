-- Review GitHub PRs without leaving Neovim: list PRs, read the diff,
-- leave line comments, approve or request changes.
-- It drives the `gh` CLI, so it uses the auth you already have.
return {
	"pwntester/octo.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	cmd = "Octo",
	keys = {
		{ "<leader>gp", "<cmd>Octo pr list<cr>", desc = "GitHub: list PRs" },
		{ "<leader>gi", "<cmd>Octo issue list<cr>", desc = "GitHub: list issues" },
		{ "<leader>gr", "<cmd>Octo review start<cr>", desc = "GitHub: start review" },
		{ "<leader>gs", "<cmd>Octo pr search<cr>", desc = "GitHub: search PRs" },
	},
	opts = {
		picker = "telescope",
		-- Show the real files from your checkout on the right side of the diff,
		-- instead of fetching them. Requires having the PR branch checked out.
		use_local_fs = true,
		default_remote = { "upstream", "origin" },
		-- Print available actions when you run `:Octo` with no arguments,
		-- useful while learning the command surface
		enable_builtin = true,
	},
}
