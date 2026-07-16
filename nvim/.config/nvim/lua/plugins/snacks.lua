-- Folke's swiss-army knife: many small QoL features in one plugin.
-- Only the pieces enabled below are active; everything else stays off.
return {
  "folke/snacks.nvim",
  priority = 1000, -- some features (bigfile) must hook in before other plugins
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true }, -- disable heavy features on huge files
    quickfile = { enabled = true }, -- render the file before plugins load
    indent = { enabled = true }, -- indentation guides
    notifier = { enabled = true }, -- vim.notify with a nicer popup UI
    input = { enabled = true }, -- nicer vim.ui.input (e.g. LSP rename)
    -- Toggleable terminal. State persists: hide it and the shell keeps running.
    terminal = {},
  },
  keys = {
    -- Ctrl+/ toggles the terminal from normal mode and from inside it.
    -- Some terminal emulators send <c-_> for Ctrl+/, so both are mapped.
    { "<c-/>", function() Snacks.terminal() end, desc = "Toggle terminal", mode = { "n", "t" } },
    { "<c-_>", function() Snacks.terminal() end, desc = "Toggle terminal", mode = { "n", "t" } },
    { "<leader>tt", function() Snacks.terminal() end, desc = "Toggle terminal" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },
  },
}
