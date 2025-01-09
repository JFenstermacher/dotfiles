return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {},
      gopls = {
        cmd_env = { GOFLAGS = "-tags=mage" },
      },
    },
  },
}
