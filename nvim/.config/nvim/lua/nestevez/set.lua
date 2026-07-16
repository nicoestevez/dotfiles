-- Line numbers (absolute on the cursor line, relative elsewhere)
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation: 4 spaces, no tabs
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Don't wrap long lines
vim.opt.wrap = false

-- Persistent undo history across sessions
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.local/state/nvim/undodir"
vim.opt.undofile = true

-- Incremental search, no lingering highlights
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true -- case-sensitive only when the pattern has uppercase

-- 24-bit colors (required by modern colorschemes)
vim.opt.termguicolors = true

-- Keep 8 lines of context when scrolling
vim.opt.scrolloff = 8

-- Always reserve the sign column for diagnostics and git signs,
-- so text doesn't shift when they appear
vim.opt.signcolumn = "yes"

-- Faster response (affects plugins like gitsigns)
vim.opt.updatetime = 50

-- Use the system clipboard
vim.opt.clipboard = "unnamedplus"

-- Open new splits below and to the right
vim.opt.splitbelow = true
vim.opt.splitright = true
