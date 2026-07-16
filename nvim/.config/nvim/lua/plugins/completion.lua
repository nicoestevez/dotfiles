-- Completion menu. The LSP knows what to suggest; blink.cmp is the UI
-- that shows and filters those suggestions as you type.
return {
  "saghen/blink.cmp",
  dependencies = { "rafamadriz/friendly-snippets" },
  -- Pinning to a release tag downloads a prebuilt fuzzy matcher binary.
  -- Tracking main instead would require a Rust toolchain to build it.
  version = "1.*",
  event = "InsertEnter",

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    -- 'default' keeps Vim's own completion feel: <C-y> accepts,
    -- <C-n>/<C-p> move, <C-e> dismisses, <C-space> opens the menu.
    -- Swap for 'super-tab' if you want VSCode-style Tab to accept.
    keymap = { preset = "default" },

    appearance = { nerd_font_variant = "mono" },

    completion = {
      -- Show the docs panel next to the menu, after a short pause
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        -- Feeds Neovim API completions from lazydev while editing this config
        lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
      },
    },

    -- Falls back to the Lua matcher if the prebuilt binary is unavailable
    fuzzy = { implementation = "prefer_rust_with_warning" },

    signature = { enabled = true },
  },
  opts_extend = { "sources.default" },
}
