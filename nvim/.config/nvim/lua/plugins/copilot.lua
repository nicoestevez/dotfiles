-- GitHub Copilot as inline ghost text. Kept separate from blink.cmp:
-- blink completes from the LSP, Copilot proposes the rest of the line
-- or block. The autocmds below keep the two from overlapping.
return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      auto_trigger = true,
      -- Without this the suggestion renders on top of the blink.cmp menu
      hide_during_completion = true,
      keymap = {
        accept = "<M-l>",
        accept_word = "<M-w>",
        accept_line = "<M-j>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
    },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      gitcommit = true,
      -- Never suggest inside files that hold secrets
      ["."] = false,
    },
  },
  config = function(_, opts)
    require("copilot").setup(opts)

    -- blink.cmp does not fire the events hide_during_completion listens to,
    -- so hide the suggestion by hand when its menu opens.
    vim.api.nvim_create_autocmd("User", {
      pattern = "BlinkCmpMenuOpen",
      callback = function()
        vim.b.copilot_suggestion_hidden = true
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      pattern = "BlinkCmpMenuClose",
      callback = function()
        vim.b.copilot_suggestion_hidden = false
      end,
    })
  end,
}
