(import-macros {: map!} :hibiscus.vim)
(import-macros {: g!} :hibiscus.vim)
(local common (require "core.common"))
(local luastr common.luastr)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Common
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(g! mapleader " ")

(map! [nx] " " "")

(map! [v] "<" "<gv")
(map! [v] ">" ">gv")

(map! [i] "jk" "<esc>")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Window
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(map! [n] "<leader>wv" ":vsplit<cr>")
(map! [n] "<leader>ws" ":split<cr>")
(map! [n] "<c-h>" (luastr "nvim-tmux-navigation" "NvimTmuxNavigateLeft"))
(map! [n] "<c-j>" (luastr "nvim-tmux-navigation" "NvimTmuxNavigateDown"))
(map! [n] "<c-k>" (luastr "nvim-tmux-navigation" "NvimTmuxNavigateUp"))
(map! [n] "<c-l>" (luastr "nvim-tmux-navigation" "NvimTmuxNavigateRight"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc Plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
