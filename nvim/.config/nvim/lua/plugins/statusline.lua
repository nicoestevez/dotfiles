-- Status line: current mode, git branch, diagnostics count, file position.
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      theme = "tokyonight",
      -- Powerline separators need a Nerd Font in your terminal.
      -- If you see boxes instead of arrows, set both to "".
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
      globalstatus = true, -- one bar for all splits, not one each
    },
    sections = {
      lualine_c = { { "filename", path = 1 } }, -- path relative to cwd
    },
  },
}
