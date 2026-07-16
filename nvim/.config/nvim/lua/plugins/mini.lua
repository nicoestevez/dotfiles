-- Small focused plugins from the mini.nvim family.
return {
  -- Auto-close brackets and quotes: type `(` and get `()` with the
  -- cursor in the middle. Deleting the opener removes the pair.
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Smarter a/i text objects: `vaf` selects a function, `via` an argument,
  -- `van` the next object. Extends the built-in `aw`, `i(`, etc.
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = {},
  },
}
