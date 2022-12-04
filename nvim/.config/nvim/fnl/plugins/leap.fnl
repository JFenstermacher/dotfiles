(import-macros {: map!} :hibiscus.vim)
(import-macros {: setup!} :core.macros)

(setup! :leap)

(map! [n] "s" "<Plug>(leap-forward-to)")
(map! [n] "S" "<Plug>(leap-backward-to)")
