-- Jump anywhere on screen: press `s`, type 2 characters of the target,
-- then the label that appears next to it. Also enhances f/t and `/` search.
return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    -- Select a growing treesitter node (function, block, etc.)
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    -- Operate on a distant text object: e.g. `yr` + jump + `iw`
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
  },
}
