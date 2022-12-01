(lambda lsp-setup-server [server-name]
  (let [{: setup} (. (require "lspconfig") server-name)]
    (setup {})))

(let [(ok? {: setup_handlers}) (pcall require "mason-lspconfig")]
  (when ok?
    (setup_handlers [lsp-setup-server])))
