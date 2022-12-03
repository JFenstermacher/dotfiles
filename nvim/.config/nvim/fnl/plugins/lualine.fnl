(let [(ok? {: setup}) (pcall require "lualine")]
  (when ok?
    (setup {:theme "gruvbox"})))
