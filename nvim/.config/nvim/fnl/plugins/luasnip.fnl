(let [(ok? {: lazy_load}) (pcall require :luasnip.loaders.from_vscode)]
  (when ok?
    (lazy_load)
    (lazy_load {:paths ["./snippets"]})))
