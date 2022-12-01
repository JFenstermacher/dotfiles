(let [(ok? treesitter) (pcall require "nvim-treesitter.configs")]
  (when ok?
    (treesitter.setup
      {:ensure_installed "all"
       :indent {:enable true}
       :highlight {:enable true
                   :additional_vim_regex_highlight false}})))
