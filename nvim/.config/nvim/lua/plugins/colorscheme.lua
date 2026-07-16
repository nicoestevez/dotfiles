return {
  "folke/tokyonight.nvim",
  lazy = false, -- load during startup, not on demand
  priority = 1000, -- load before every other plugin
  config = function()
    require("tokyonight").setup({
      style = "night",
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
