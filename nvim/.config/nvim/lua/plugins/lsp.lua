-- LSP: the language server does the heavy lifting (go-to-definition,
-- diagnostics, rename, hover docs). Neovim is only the client.
--
-- Three plugins cooperate here:
--   mason.nvim          -- downloads the server binaries
--   nvim-lspconfig      -- ships sane default config for each server
--   mason-lspconfig     -- bridges the two and enables what's installed
return {
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "lua_ls", -- Lua (including this config)
        -- vtsls over ts_ls: ts_ls looks for TypeScript in the workspace and
        -- fails on standalone files, vtsls bundles its own.
        "vtsls", -- TypeScript / JavaScript
        "basedpyright", -- Python types
        "ruff", -- Python linting + formatting
        "prismals", -- Prisma schema
      },
      -- Installed servers are enabled automatically via vim.lsp.enable().
      -- This is the default, spelled out so it's not a mystery.
      automatic_enable = true,
    },
    config = function(_, opts)
      require("mason-lspconfig").setup(opts)

      -- Per-server tweaks. On Neovim 0.11+ this is vim.lsp.config(), which
      -- replaces the old require("lspconfig").server.setup({}) you'll see
      -- in most tutorials.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            -- Stop it from asking which Lua version this project uses
            runtime = { version = "LuaJIT" },
            -- `vim` is a real global in Neovim config, not a typo
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              -- "strict" is very noisy on existing code; start here
              typeCheckingMode = "standard",
            },
          },
        },
      })

      -- How diagnostics look. Without this, errors show up inline but
      -- unsorted and unlabeled.
      vim.diagnostic.config({
        virtual_text = { prefix = "●", source = "if_many" },
        severity_sort = true,
        float = { border = "rounded", source = "if_many" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      -- Keymaps that only make sense once a server is attached to a buffer.
      -- Neovim 0.11+ already binds grn (rename), gra (code action),
      -- grr (references) and K (hover) by default; these are the more
      -- conventional bindings on top.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", vim.lsp.buf.references, "List references")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cd", vim.diagnostic.open_float, "Show diagnostic")
          map("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Previous diagnostic")
          map("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
        end,
      })
    end,
  },

  -- Gives lua_ls full knowledge of the Neovim API, so you get completion
  -- and docs while editing this config. Only loads for Lua files.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },
}
