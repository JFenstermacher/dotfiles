require 'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true,
    disable = {
      -- 'elixir'
    }
  },
  indent = {
    enable = true,
    disable = {
      -- 'elixir',
      'python'
    }
  }
}
