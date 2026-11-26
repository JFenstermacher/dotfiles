return {
  -- Sticky function/class/block header while scrolling diffs and search results
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "LazyFile",
    opts = {
      mode = "cursor",
      max_lines = 4,
    },
    keys = {
      {
        "[C",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Jump to Enclosing Context",
      },
    },
  },

  -- Multi-file structured ripgrep search UI (great for complex filters, paths, flags)
  {
    "MagicDuck/grug-far.nvim",
    opts = {
      headerMaxWidth = 80,
      windowCreationCommand = "vsplit",
    },
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open({ transient = true })
        end,
        mode = { "n", "x" },
        desc = "Search Panel (grug-far)",
      },
      {
        "<leader>sf",
        function()
          require("grug-far").open({
            transient = true,
            prefills = { paths = vim.fn.expand("%") },
          })
        end,
        mode = { "n", "x" },
        desc = "Search Current File (grug-far)",
      },
    },
  },

  -- Register <leader>d group label in which-key
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>d", group = "diff" },
      },
    },
  },
}
