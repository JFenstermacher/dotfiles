(import-macros {: map!} :hibiscus.vim)
(import-macros {: g!} :hibiscus.vim)

(g! mapleader " ")

(map! [nx] " " "")
(map! [n] "<leader>wv" ":vsplit<cr>")
(map! [n] "<leader>ws" ":split<cr>")

(map! [v] "<" "<gv")
(map! [v] ">" ">gv")

(map! [i] "jk" "<esc>")
