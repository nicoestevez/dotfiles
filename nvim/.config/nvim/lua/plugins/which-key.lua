-- Pops up a panel showing available keymaps when you pause after <leader>
-- (or any prefix). Makes the whole config discoverable without memorizing.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- Label the keymap groups this config already uses
    spec = {
      { "<leader>p", group = "project" },
      { "<leader>h", group = "git hunks" },
      { "<leader>g", group = "github" },
      { "<leader>t", group = "terminal" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Keymaps for this buffer",
    },
  },
}
