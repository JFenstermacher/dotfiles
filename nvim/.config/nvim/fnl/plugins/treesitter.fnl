(let [(ok? treesitter) (pcall require "nvim-treesitter.configs")]
  (when ok?
    (treesitter.setup {:ensure_installed "all"
                       :rainbow {:enable true
                                 :extended_mode true 
                                 :max_file_lines nil}
                       :indent {:enable true}
                       :highlight {:enable true
                                   :additional_vim_regex_highlight false}})))
