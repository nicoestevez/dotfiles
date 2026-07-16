-- Shows which lines you added/changed/removed in the sign column,
-- and lets you stage or revert individual hunks without leaving the buffer.
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = require("gitsigns")

      local function map(mode, keys, fn, desc)
        vim.keymap.set(mode, keys, fn, { buffer = bufnr, desc = "Git: " .. desc })
      end

      -- Navigate between changed hunks
      map("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
      map("n", "[c", function() gs.nav_hunk("prev") end, "Previous hunk")

      map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
      map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
      map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
      map("n", "<leader>hd", gs.diffthis, "Diff against index")
      -- Inline blame, off by default because it's distracting while typing
      map("n", "<leader>ht", gs.toggle_current_line_blame, "Toggle line blame")
    end,
  },
}
