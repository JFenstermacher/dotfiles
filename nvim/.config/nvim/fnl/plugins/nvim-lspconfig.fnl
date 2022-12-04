(import-macros {: merge-tbl} :hibiscus.core)
(import-macros {: map!} :hibiscus.vim)
(local {: lua-str} (require :core.common))

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

(local default-config
  (let [(cmp-nvim-lsp-ok? {: default_capabilities}) (pcall require :cmp_nvim_lsp)
        server-config {:on_attach on-attach}]
    (when cmp-nvim-lsp-ok?
      (tset server-config :capabilities (default_capabilities))) server-config))

(local server-configs {:defaults default-config
                       :tsserver {:flags {:debounce_text_changes 150}
                                  :on_attach (fn [client bufnr]
                                               (tset client :server_capabilities :document_formatting false)
                                               (on-attach client bufnr))}
                       :sumneko_lua {:settings {:Lua {:diagnostics {:globals "vim"}
                                                      :workspace {:library {(vim.fn.expand :$VIMRUNTIME/lua) true
                                                                            (vim.fn.expand :$VIMRUNTIME/lua/vim/lsp) true}
                                                                  :maxPreload 10000
                                                                  :preloadFileSize 10000}}}}})

(fn get-server-config [server-name]
  (let [{: defaults} server-configs]
    (merge-tbl defaults
      (-> server-configs
        (. server-name)
        (or {})))))

(let [(ok? {: setup_handlers}) (pcall require :mason-lspconfig)]
  (when ok?
    (setup_handlers [(fn [server-name]
                       (let [{: setup} (. (require :lspconfig) server-name)]
                         (setup (get-server-config server-name))))])))
