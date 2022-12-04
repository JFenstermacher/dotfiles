(import-macros {: map!} :hibiscus.vim)
(import-macros {: g!} :hibiscus.vim)
(local {: lua-str : cmd-str} (require "core.common"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Common
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(g! mapleader " ")
(g! maplocalleader ",")

(map! [nx] " " "")

(map! [v] "<" "<gv")
(map! [v] ">" ">gv")

(map! [i] "jk" "<esc>")

(map! [n] "<c-u>" "<c-u>zz")  ;; Centers screen when paging up
(map! [n] "<c-d>" "<c-d>zz")  ;; Centers screen when paging down

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Window
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(map! [n] "<leader>wv" ":vsplit<cr>")
(map! [n] "<leader>ws" ":split<cr>")

(map! [n] "<c-h>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateLeft()"))
(map! [n] "<c-j>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateDown()"))
(map! [n] "<c-k>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateUp()"))
(map! [n] "<c-l>" (lua-str "require('nvim-tmux-navigation').NvimTmuxNavigateRight()"))

(map! [n] "<leader>w=" "<c-w>=")
(map! [n] "<leader>w-" "<c-w>_<c-w>|")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc Plugin
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(map! [nv] "ga" "<Plug>(EasyAlign)")

(map! [n] "<leader>gs"  (cmd-str "Git"))
(map! [n] "<leader>gcb" (cmd-str "Git blame"))
(map! [n] "<leader>gd"  (cmd-str "Gdiff"))
(map! [n] "<leader>gp"  (cmd-str "Git push"))
(map! [n] "<leader>gl"  (cmd-str "Git pull"))
(map! [n] "<leader>gf"  (cmd-str "Git fetch"))
(map! [n] "<leader>gcc" (cmd-str "Git commit --verbose"))
(map! [n] "<leader>gca" (cmd-str "Git commit --all --verbose"))
(map! [n] "<leader>gdl" (cmd-str "diffget LOCAL"))
(map! [n] "<leader>gdr" (cmd-str "diffget REMOTE"))
