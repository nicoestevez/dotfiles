return {
  name = "codeowners.nvim",
  dir = vim.fn.stdpath("config") .. "/vendor/codeowners.nvim",
  lazy = true,
  opts = { icon = "Owners:", separator = ", " },
}
