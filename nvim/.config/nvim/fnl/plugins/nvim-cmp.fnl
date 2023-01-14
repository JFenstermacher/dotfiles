(let [(cmp-ok? cmp) (pcall require :cmp)
      (autopairs-ok? autopairs) (pcall require :nvim-autopairs.completion.cmp)]
  (when (and cmp-ok? autopairs-ok?)
    (cmp.setup 
      {:snippet {:expand (fn [args]
                          (let [{: body} args
                                {: lsp_expand} (require :luasnip)]
                            (lsp_expand body)))}
       :window {:completion (cmp.config.window.bordered)
                :documentation (cmp.config.window.bordered)}
       :sources (cmp.config.sources [{:name "nvim_lsp"} {:name "luasnip"}]
                                    [{:name "buffer"}])
       :mapping (cmp.mapping.preset.insert {"<c-b>" (cmp.mapping.scroll_docs 4)
                                            "<c-f>" (cmp.mapping.scroll_docs 4)
                                            "<c-space>" (cmp.mapping.complete)
                                            "<c-e>" (cmp.mapping.abort)
                                            "<cr>" (cmp.mapping.confirm {:select true})})})

    (cmp.setup.cmdline ["/" "?"]
                       {:mapping (cmp.mapping.preset.cmdline)
                        :sources [{:name "buffer"}]})

    (cmp.setup.cmdline ":" 
                        {:mapping (cmp.mapping.preset.cmdline)
                         :sources (cmp.config.sources [{:name "path"}]
                                                      [{:name "cmdline"}])})
    (cmp.event:on "confirm_done" (autopairs.on_confirm_done))))
