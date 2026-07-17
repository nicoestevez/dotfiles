-- Treesitter parses your code into a syntax tree, which gives Neovim
-- accurate highlighting, folding and indentation -- far better than the
-- regex-based highlighting Vim ships with.
local languages = {
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "query", -- treesitter's own query language
  "python",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "json",
  "yaml",
  "toml",
  "prisma",
  "markdown",
  "markdown_inline",
  "bash",
  "git_config",
  "gitcommit",
  "diff",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main", -- the master branch is frozen; main is the current rewrite
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install(languages)

    -- The main branch no longer enables features for you: you turn them on
    -- per filetype. This fires whenever a buffer's filetype is set.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(event)
        local ft = event.match
        -- Map the filetype to a parser name, then bail out if that parser
        -- isn't installed -- otherwise every unrelated filetype errors.
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang or not vim.tbl_contains(languages, lang) then
          return
        end

        vim.treesitter.start() -- highlighting (built into Neovim)

        -- Folding (built into Neovim). Folds start open; use zc to close one.
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldmethod = "expr"
        vim.wo.foldlevel = 99

        -- Indentation (provided by nvim-treesitter, still experimental)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
