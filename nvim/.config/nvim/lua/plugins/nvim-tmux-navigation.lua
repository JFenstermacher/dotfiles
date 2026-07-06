return {
  "nvim-herdr-navigation",
  dev = true,
  lazy = false,
  config = function()
    require("nvim-herdr-navigation")
  end,
  keys = {
    { "<c-h>", ":NvimHerdrNavigateLeft<cr>",  desc = "Navigate left window",  silent = true },
    { "<c-j>", ":NvimHerdrNavigateDown<cr>",  desc = "Navigate down window",  silent = true },
    { "<c-k>", ":NvimHerdrNavigateUp<cr>",    desc = "Navigate up window",    silent = true },
    { "<c-l>", ":NvimHerdrNavigateRight<cr>", desc = "Navigate right window", silent = true },
  },
}