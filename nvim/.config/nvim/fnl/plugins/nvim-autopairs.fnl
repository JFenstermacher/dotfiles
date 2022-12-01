(let [(ok? {: setup}) (pcall require "nvim-autopairs")]
  (when ok?
    (setup {:disable_filetype ["TelescopePrompt" "clojure" "fennel"]})))
