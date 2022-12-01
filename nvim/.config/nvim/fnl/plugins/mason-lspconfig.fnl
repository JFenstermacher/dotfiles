(let [(ok? {: setup}) (pcall require "mason-lspconfig")]
  (when ok?
    (setup)))
