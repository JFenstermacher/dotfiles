return {
  "alexghergh/nvim-tmux-navigation",
  config = true,
  event = "BufReadPre",
  keys = {
    { "<c-h", ":NvimTmuxNavigateLeft<cr>", desc = "Navigate left window", silent = true },
    { "<c-j>", ":NvimTmuxNavigateDown<cr>", desc = "Navigate down window", silent = true },
    { "<c-k>", ":NvimTmuxNavigateUp<cr>", desc = "Navigate up window", silent = true },
    { "<c-l>", ":NvimTmuxNavigateRight<cr>", desc = "Navigate right window", silent = true },
  },
}
