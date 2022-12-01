(import-macros {: map!} :hibiscus.vim)

(let [(ok? {: setup}) (pcall require "nvim-surround")]
    (setup))
