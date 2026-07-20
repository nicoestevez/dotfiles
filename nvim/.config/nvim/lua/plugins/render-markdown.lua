-- Renders Markdown inside the buffer as you edit: styled headers, bullets,
-- checkboxes, tables, code blocks and callouts -- no browser needed. Rendering
-- relaxes around the cursor so the raw text stays editable on the current line.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- markdown parser, already installed
    "nvim-tree/nvim-web-devicons", -- icon provider
  },
  ---@module "render-markdown"
  ---@type render.md.UserConfig
  opts = {},
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown buf_toggle<cr>", desc = "Markdown render toggle" },
  },
}
