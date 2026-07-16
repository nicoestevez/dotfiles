vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Leave terminal mode with a double Esc (single Esc stays available
-- for TUI apps running inside the terminal)
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
