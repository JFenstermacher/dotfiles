(import-macros {: setup!} :core.macros)

(let [(ok? {: setup}) (pcall require "nvim-treesitter.configs")]
  (when ok?
    (setup {:ensure_installed "all"
            :rainbow {:enable true
                      :extended_mode true 
                      :max_file_lines nil}
            :indent {:enable true}
            :highlight {:enable true
                        :additional_vim_regex_highlight false}
            :textobjects {:select {:enable true
                                   :lookahead true
                                   :keymaps {:af "@function.outer"
                                             :if "@function.inner"
                                             :ac "@class.outer"
                                             :ic "@class.inner"}}}})))

