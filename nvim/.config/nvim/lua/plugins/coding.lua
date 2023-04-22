return {
  {
    "hrsh7th/cmp-nvim-lsp",
    dependencies = { "hrsh7th/cmp-cmdline" },
    config = function(_, opts)
      local cmp = require("cmp")

      vim.tbl_deep_extend("force", opts, {
        performance = {
          fetching_timeout = 80,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp", keyword_length = 6, group_index = 1, max_item_count = 30 },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      cmp.setup(opts)

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "buffer" } }),
      })

      cmp.setup.cmdline({ ":" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
        }),
      })
    end,
  },
  {
    "Olical/conjure",
    ft = { "clojure", "fennel" },
  },
  {
    "eraserhd/parinfer-rust",
    build = "cargo build --release",
    ft = { "clojure", "fennel" },
  },
  {
    "junegunn/vim-easy-align",
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = { "n", "v" }, desc = "Align elements" },
    },
  },
  {
    "clojure-vim/vim-jack-in",
    dependencies = {
      "tpope/vim-dispatch",
      "radenling/vim-dispatch-neovim",
    },
    cmd = { "Boot", "Clj", "Lein" },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = "BufReadPre",
    dependencies = { "mason.nvim" },
    opts = function(_, opts)
      local nls = require("null-ls")
      table.insert(opts.sources, nls.builtins.formatting.stylua)
      table.insert(opts.sources, nls.builtins.formatting.prettierd)
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      table.insert(opts.ensure_installed, "prettierd")
    end,
  },
  {
    "edgedb/edgedb-vim",
  },
}
