(import-macros {: map! : exec} :hibiscus.vim)
(local {: cmdstr} (require "core.common"))

(let [(ok? {: setup : load_extension}) (pcall require "telescope")]
  (when ok?
    (let [actions (require "telescope.actions")
          sorters (require "telescope.sorters")
          previewers (require "telescope.previewers")
          fb-actions (. (require "telescope") "extensions" "file_browser" "actions")]
      (setup
        {:defaults {:file_sorter sorters.get_fzy_sorter
                    :file_previewer previewers.vim_buffer_cat.new
                    :grep_previewer previewers.vim_buffer_vimgrep.new
                    :qflist_previewer previewers.vim_buffer_qflist.new
                    :color_devicons true}
         :pickers {:find_files {:find_command ["fd" "--type" "f" "--hidden" "--exclude" ".git"]}}
         :extensions {:file_browser {:hide_parent_dir true
                                     :respect_gitignore false
                                     :theme "ivy"
                                     :mappings {:n {"-" fb-actions.goto_parent_dir}}}}
         :fzy_native {:override_generic_sorter false
                      :override_file_sorter true}})
      (load_extension "fzy_native")
      (load_extension "file_browser"))))

(map! [n] "<leader>fb" (cmdstr "Telescope buffers"))
(map! [n] "<leader>fw" (cmdstr "Telescope live_grep"))
(map! [n] "<leader>pf" (cmdstr "Telescope find_files"))
(map! [n] "<leader>fq" (cmdstr "Telescope quickfix"))
(map! [n] "-" (cmdstr "Telescope file_browser path=%:p:h"))
