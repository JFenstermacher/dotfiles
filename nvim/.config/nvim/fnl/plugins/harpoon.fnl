(import-macros {: fstring} :hibiscus.core)
(import-macros {: map!} :hibiscus.vim)
(import-macros {: setup!} :core.macros)
(local {: lua-str} (require "core.common"))

((setup! :harpoon))

(map! [n] "<leader>ht" (lua-str "require('harpoon.mark').add_file()"))
(map! [n] "<leader>1" (lua-str "require('harpoon.ui').nav_file(1)"))
(map! [n] "<leader>2" (lua-str "require('harpoon.ui').nav_file(2)"))
(map! [n] "<leader>3" (lua-str "require('harpoon.ui').nav_file(3)"))
(map! [n] "<leader>4" (lua-str "require('harpoon.ui').nav_file(4)"))
