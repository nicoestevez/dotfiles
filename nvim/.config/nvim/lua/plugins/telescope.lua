-- Fuzzy finder. This ends up being the main way you move around a project:
-- open files by name, grep the whole codebase, jump to a symbol.
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Native C matcher: noticeably faster sorting on big projects.
    -- Needs `make`, which you have.
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    { "<C-p>", "<cmd>Telescope git_files<cr>", desc = "Find git files" },
    { "<leader>pg", "<cmd>Telescope live_grep<cr>", desc = "Grep project" },
    { "<leader>pb", "<cmd>Telescope buffers<cr>", desc = "Open buffers" },
    { "<leader>ph", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    { "<leader>pd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    -- Grep for the word under the cursor
    {
      "<leader>ps",
      function()
        require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
      end,
      desc = "Grep word under cursor",
    },
  },
  config = function()
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        -- Esc closes the picker straight from insert mode, instead of
        -- dropping into normal mode first
        mappings = {
          i = { ["<esc>"] = require("telescope.actions").close },
        },
      },
      pickers = {
        find_files = { hidden = true },
      },
    })

    pcall(telescope.load_extension, "fzf")
  end,
}
