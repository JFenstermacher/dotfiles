return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "mrjones2014/nvim-ts-rainbow" },
    version = false, -- last release is way too old and doesn't work on Windows
    build = ":TSUpdate",
    event = "BufReadPost",
    keys = {
      { "<c-space>", desc = "Increment selection" },
      { "<bs>", desc = "Schrink selection", mode = "x" },
    },
    ---@type TSConfig
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      context_commentstring = { enable = true, enable_autocmd = false },
      ensure_installed = {
        "bash",
        "help",
        "html",
        "ini",
        "javascript",
        "json",
        "go",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "terraform",
        "typescript",
        "vim",
        "yaml",
      },
      rainbow = {
        enable = true,
        extended_mode = true,
        max_file_lines = nil,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<nop>",
          node_decremental = "<bs>",
        },
      },
    },
  },
}
