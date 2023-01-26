return {
  {
    "alexghergh/nvim-tmux-navigation",
    config = true,
    event = "BufReadPre",
    keys = {
      { "<c-h", ":NvimTmuxNavigateLeft<cr>", desc = "Navigate left window", silent = true },
      { "<c-j>", ":NvimTmuxNavigateDown<cr>", desc = "Navigate down window", silent = true },
      { "<c-k>", ":NvimTmuxNavigateUp<cr>", desc = "Navigate up window", silent = true },
      { "<c-l>", ":NvimTmuxNavigateRight<cr>", desc = "Navigate right window", silent = true },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "-", ":Telescope file_browser path=%:p:h<cr>", desc = "File browser" },
    },
    dependencies = {
      "nvim-telescope/telescope-fzy-native.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      local defaults = {
        extensions = {
          file_browser = {
            initial_mode = "normal",
            hide_parent_dir = true,
            respect_gitignore = false,
            hidden = true,
            theme = "ivy",
            mappings = {
              n = {
                ["/"] = { "i", type = "command" },
                ["-"] = telescope.extensions.file_browser.actions.goto_parent_dir,
                ["<C-c>"] = actions.close,
              },
            },
          },

          fzy_native = {
            override_generic_sorter = true,
            override_file_sorter = true,
          },
        },
      }

      telescope.setup(vim.tbl_deep_extend("keep", defaults, opts))

      local extensions = {
        "fzy_native",
        "file_browser",
      }

      for _, ext in ipairs(extensions) do
        telescope.load_extension(ext)
      end
    end,
  },
  {
    "ggandor/leap.nvim",
    event = "VeryLazy",
    keys = {
      { "s", "<Plug>(leap-forward-to)", mode = { "n", "x", "o" }, silent = true },
      { "S", "<Plug>(leap-backward-to)", mode = { "n", "x", "o" }, silent = true },
      { "gs", "<Plug>(leap-cross-window)", mode = { "n", "x", "o" }, silent = true },
    },
    dependencies = { { "ggandor/flit.nvim", opts = { labeled_modes = "nv" } } },
    config = true,
  },
  { "folke/persistence.nvim", enabled = false },
}
