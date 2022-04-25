require 'nvim-treesitter.configs'.setup {
  ensure_installed = "all",
  ignore_install = {"phpdoc"},
  highlight = {
    enable = true,
    additional_vim_regex_hightlighting = false,
  },
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  },
  autopairs = {
    enable = true,
  },
  indent = {
    enable = true,
  },
  rainbow = {
    enable = true,
    disable = { "html" },
    extended_mode = false,
    max_file_lines = nil,
  },
  autotag = {
    enable = true
  },
}
