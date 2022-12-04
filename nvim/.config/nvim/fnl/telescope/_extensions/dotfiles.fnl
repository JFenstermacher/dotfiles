(import-macros {: fstring} :hibiscus.core)

(local telescope (require :telescope))
(local finders (require :telescope.finders))
(local pickers (require :telescope.pickers))
(local make-entry (require :telescope.make_entry))
(local conf (. (require :telescope.config) :values))
(local dot-path (fstring "$(. vim :env :HOME)/.config/nvim"))

(fn list-dotfiles [dot-path]
  (let [p (io.popen (fstring "rg --files --hidden ${dot-path}"))]
    (icollect [line (p:lines)] line)))

(fn dotfiles [opts?]
  (local opts (or opts? {}))
  (local picker (pickers.new opts 
                             {:prompt_title "find in dotfiles"
                              :results_title "Dotfiles"
                              :finder {:finder (finders.new_table {:results (list-dotfiles)
                                                                   :entry_maker (make-entry.gen_from_file opts)
                                                                   :previewer (conf.file_previewer opts)
                                                                   :sorter (conf.file_sorter opts)})}}))
  (picker:find))

(telescope.register_extension {:exports {:dotfiles dotfiles}})
