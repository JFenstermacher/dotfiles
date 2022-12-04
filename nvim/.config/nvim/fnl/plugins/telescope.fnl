(import-macros {: fstring} :hibiscus.core)
(import-macros {: map!} :hibiscus.vim)
(local {: cmd-str} (require "core.common"))

(fn load-extension [ext] 
  (let [{: load_extension} (require :telescope)]
    (let [(loaded? err) (pcall load_extension ext)]
      (when (not loaded?)
        (print (fstring "Telescope extension ${ext} failed to load: ${err}"))))))

(let [(ok? {: setup}) (pcall require :telescope)]
  (when ok?
    (let [actions (require "telescope.actions")
          sorters (require "telescope.sorters")
          previewers (require "telescope.previewers")
          fb-actions (. (require "telescope") :extensions :file_browser :actions)]
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
      (load-extension :fzy_native)
      (load-extension :file_browser)
      (load-extension :harpoon)
      (load-extension :dotfiles))))

(map! [n] "<leader>fb" (cmd-str "Telescope buffers"))
(map! [n] "<leader>fd" (cmd-str "Telescope dotfiles"))
(map! [n] "<leader>fw" (cmd-str "Telescope live_grep"))
(map! [n] "<leader>pf" (cmd-str "Telescope find_files"))
(map! [n] "<leader>fq" (cmd-str "Telescope quickfix"))
(map! [n] "<leader>fk" (cmd-str "Telescope keymaps"))
(map! [n] "<leader>fh" (cmd-str "Telescope harpoon marks"))
(map! [n] "-"          (cmd-str "Telescope file_browser path=%:p:h"))
