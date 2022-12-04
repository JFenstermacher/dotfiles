(import-macros {: dump : merge!} :hibiscus.core)

(local pad-length 45)

(lambda right-pad [str ?len]
  (let [len (or ?len pad-length)]
    (string.format (.. "%-" len "s") str)))

(local config {:preview_command "cat"
               :preview_file_path (.. vim.env.HOME :/.config/nvim/static/logo.txt)
               :preview_file_height 15
               :preview_file_width 35
               :custom_center [{:icon " " 
                                :desc (right-pad "Find file")
                                :action (right-pad "Telescope find_files find_command=rg,--hidden,--files")
                                :shortcut "SPC p f"}
                               {:icon " "
                                :desc (right-pad "Recents")
                                :action (right-pad "Telescope oldfiles")
                                :shortcut "SPC f o"}
                               {:icon " "
                                :desc (right-pad "Find Word")
                                :action (right-pad "Telescope live_grep")
                                :shortcut "SPC f w"}]})

(let [(ok? db) (pcall require :dashboard)]
  (when ok?
    (each [key val (pairs config)]
      (tset db key val))))
