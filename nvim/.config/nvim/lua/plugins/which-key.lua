-- Pops up a panel showing available keymaps when you pause after <leader>
-- (or any prefix). Makes the whole config discoverable without memorizing.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- Label the keymap groups this config already uses
    spec = {
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>p", group = "project" },
      { "<leader>h", group = "git hunks" },
      { "<leader>g", group = "github" },
      { "<leader>t", group = "terminal" },
      { "<leader>u", group = "ui/toggle" },
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
