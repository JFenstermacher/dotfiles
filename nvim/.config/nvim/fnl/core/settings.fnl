(import-macros {: fstring} :hibiscus.core)
(import-macros {: g! : set!} :hibiscus.vim)

(local {: cache-path : is-macos?} (require "core.common"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Options
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set! mouse "")                                                ;; Shuts off mouse support
(set! clipboard [:unnamedplus])                                ;; Uses correct register
(set! swapfile false)                                          ;; Swapfiles are annoying
(set! termguicolors true)                                      ;; Better colors
(set! wildignorecase true)                                     ;; When completing filenames and directories
(set! virtualedit [:block])                                    ;; Cursor can be placed within tab within virtual mode
(set! timeoutlen 500)                                          ;; Time to wait for mapped sequence to complete
(set! ignorecase true)                                         ;; When searching ignorecase 
(set! smartcase true)                                          ;; When capitalize letter in search, ignore ignorecase
(set! infercase true)                                          ;; Completions adjusted based on typed text 
(set! relativenumber true)                                     ;; Show relative line numbers
(set! number true)                                             ;; Show linenumber seperatef from relative line number
(set! splitbelow true)                                         ;; Split buffer below
(set! completeopt [:menu :menuone :noselect])                  ;; Completion menu options
(set! showmode false)                                          ;; Shows current mode in message
(set! scrolloff 2)                                             ;; Minimum rows to keep at bottom of screen
(set! cmdheight 0)                                             ;; How many lines to give to the commandline
(set! colorcolumn "120")                                       ;; Color column highlight
(set! ruler false)                                             ;; Column and cursor position
(set! pumheight 15)                                            ;; Max items to display in popup menu
(set! list true)                                               ;; Show tabs and trailing spaces as other characters
(set! listchars "tab:»·,nbsp:+,trail:·,extends:→,precedes:←")  ;; Specifies what characters to show
(set! undofile true)                                           ;; Store undo operations in file

(set! smarttab true)
(set! expandtab true)
(set! tabstop 2)
(set! shiftwidth 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Directories
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set! directory (fstring "${cache-path}/swap/"))                ;; Swapfile directories
(set! undodir (fstring "${cache-path}/undo/"))                  ;; Undofile directories
(set! viewdir (fstring "${cache-path}/view/"))                  ;; :mkview file directories
(set! spellfile (fstring "${cache-path}/spell/en.utf-8.add"))   ;; zg and zw commands added here

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Disable Distribution Plugins
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(g! load_gzip 1)
(g! loaded_tar 1)
(g! loaded_tarPlugin 1)
(g! loaded_zip 1)
(g! loaded_zipPlugin 1)
(g! loaded_getscript 1)
(g! loaded_getscriptPlugin 1)
(g! loaded_vimball 1)
(g! loaded_vimballPlugin 1)
(g! loaded_matchit 1)
(g! loaded_matchparen 1)
(g! loaded_2html_plugin 1)
(g! loaded_logiPat 1)
(g! loaded_rrhelper 1)
(g! loaded_netrw 1)
(g! loaded_netrwPlugin 1)
(g! loaded_netrwSettings 1)
(g! loaded_netrwFileHandlers 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MacOS Settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when (is-macos?)
    (g! clipboard {:name "macOS-clipboard"
                   :copy {"+" "pbcopy"
                          "*" "pbcopy"}
                   :paste {"+" "pbpaste"
                           "*" "pbpaste"}
                   :cache_enabled 0}))
