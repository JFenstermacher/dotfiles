return {
  {
    "hrsh7th/cmp-nvim-lsp",
    dependencies = { "hrsh7th/cmp-cmdline" },
    config = function(_, opts)
      local cmp = require("cmp")

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
}
