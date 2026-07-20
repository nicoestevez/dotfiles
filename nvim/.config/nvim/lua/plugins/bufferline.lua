-- Shows open buffers as clickable tabs along the top, VSCode-style.
-- These are buffers, not vim tabpages: one entry per open file.
return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  event = "VeryLazy",
  opts = {
    options = {
      diagnostics = "nvim_lsp", -- show LSP error/warning counts on each tab
      always_show_bufferline = true,
      show_buffer_close_icons = true,
      -- Keep the bar out of the way when the snacks explorer is open,
      -- so it doesn't draw over the sidebar.
      offsets = {
        { filetype = "snacks_picker_list", text = "Explorer", separator = true },
      },
    },
  },
  keys = {
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
    { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
  },
}
