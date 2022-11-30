(import-macros {: map!} :hibiscus.vim)
(import-macros {: exec} :hibiscus.vim)

(let [(ok? telescope) (pcall require "telescope")
      actions (require "telescope.actions")]
  (when ok?
    (telescope.setup
      {:default
       {:mappings
        {:i {"<C-q>" actions.send_to_qflist}} }})
    (telescope.load_extension "fzf")))

(map! [n] "<leader>b" (exec [[":Telescope buffers"]]))
(map! [n] "<leader>fw" (exec [["Telescope live_grep"]]))
(map! [n] "<leader>ff" (exec [["Telescope find_files"]]))
(map! [n] "<leader>fq" (exec [["Telescope quickfix"]]))
(map! [n] "-" (exec [["Telescope file_browser path=%:p:h"]]))
