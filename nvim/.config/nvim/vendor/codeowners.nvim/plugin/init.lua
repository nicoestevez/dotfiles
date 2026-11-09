if vim.g.loaded_codeowners then
  return
end
vim.g.loaded_codeowners = 1

if vim.fn.has('nvim-0.5') == 0 then
  vim.api.nvim_echo({ { 'codeowners.nvim requires Neovim >= 0.5', 'ErrorMsg' } }, true, { err = true })
  return
end

require('codeowners').setup()
