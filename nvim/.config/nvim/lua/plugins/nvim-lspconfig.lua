return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {},
      tsgo = {},
      gopls = {
        cmd_env = { GOFLAGS = "-tags=mage" },
      },
    },
  },
}
