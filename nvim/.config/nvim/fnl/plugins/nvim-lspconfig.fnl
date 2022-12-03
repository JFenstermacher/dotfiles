(import-macros {: map!} :hibiscus.vim)
(local {: lua-str} (require "core.common"))

(lambda on-attach [client bufnr]
  (map! [n] "gD" (lua-str "vim.lsp.buf.declaration()"))
  (map! [n] "gk" (lua-str "vim.lsp.buf.signature_help()"))
  (map! [n] "gR" (lua-str "vim.lsp.buf.rename()"))
  (map! [n] "gT" (lua-str "vim.lsp.buf.type_definition()"))
  (map! [nx] "ga" (lua-str "vim.lsp.buf.code_action()"))
  (map! [n] "gd" (lua-str "vim.lsp.buf.definition()"))
  (map! [n] "gi" (lua-str "vim.lsp.buf.implementation()"))
  (map! [n] "K" (lua-str "vim.lsp.buf.hover()"))
  (map! [n] "gr" (lua-str "vim.lsp.buf.references()"))
  (map! [n] "glf" (lua-str "vim.lsp.buf.format({ async = true})"))
  (map! [n] "gld" (lua-str "vim.diagnostic.open_float()"))
  (map! [n] "glq" (lua-str "vim.diagnostic.setloclist()"))
  (map! [n] "qlQ" (lua-str "vim.diagnostic.setqflist()")))

(lambda lsp-setup-server [server-name]
  (let [{: setup} (. (require "lspconfig") server-name)
        (cmp-nvim-lsp-ok? {: default_capabilities}) (pcall require "cmp_nvim_lsp")
        server-config {:on_attach on-attach}]
    (when cmp-nvim-lsp-ok?
      (tset server-config :capabilities (default_capabilities)))
    (setup server-config)))

(let [(ok? {: setup_handlers}) (pcall require "mason-lspconfig")]
  (when ok?
    (setup_handlers [lsp-setup-server])))