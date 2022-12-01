(import-macros {: map!} :hibiscus.vim)

(let [(ok? {: setup}) (pcall require "leap")]
  (when ok?
    (setup {})))

(map! [n] "s" "<Plug>(leap-forward-to)")
(map! [n] "S" "<Plug>(leap-backward-to)")
