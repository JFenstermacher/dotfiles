(import-macros {: fstring : dump} :hibiscus.core)

(local telescope (require :telescope))
(local finders (require :telescope.finders))
(local pickers (require :telescope.pickers))
(local make-entry (require :telescope.make_entry))
(local conf (. (require :telescope.config) :values))
(local dot-path (fstring "$(. vim :env :HOME)/workspace/dotfiles"))

(fn list-dotfiles []
  (let [p (io.popen (fstring "fd --type f --hidden --exclude .git"))]
    (icollect [line (p:lines)] line)))

(fn dotfiles [opts?]
  (local opts (or opts? {}))
  (local picker (pickers.new opts {:prompt_title "find in dotfiles"
                                   :results_title "Dotfiles"
                                   :previewer (conf.file_previewer opts)
                                   :sorter (conf.file_sorter opts)
                                   :finder (finders.new_table {:results (list-dotfiles)
                                                               :entry_maker (make-entry.gen_from_file opts)})}))
  (picker:find))

(telescope.register_extension {:exports {:dotfiles dotfiles}})
