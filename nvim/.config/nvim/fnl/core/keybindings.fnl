(import-macros {: map!} :hibiscus.vim)
(import-macros {: g!} :hibiscus.vim)
(local {: lua-str} (require "core.common"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Common
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(g! mapleader " ")
(g! maplocalleader ",")

(map! [nx] " " "")

(map! [v] "<" "<gv")
(map! [v] ">" ">gv")

(map! [i] "jk" "<esc>")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Window
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(map! [n] "<leader>wv" ":vsplit<cr>")
(map! [n] "<leader>ws" ":split<cr>")
(map! [n] "<c-h>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateLeft()"))
(map! [n] "<c-j>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateDown()"))
(map! [n] "<c-k>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateUp()"))
(map! [n] "<c-l>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateRight()"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc Plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
