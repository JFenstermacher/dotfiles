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
    "junegunn/vim-easy-align",
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = { "n", "v" }, desc = "Align elements" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      autoformat = true,
    },
  },
}
