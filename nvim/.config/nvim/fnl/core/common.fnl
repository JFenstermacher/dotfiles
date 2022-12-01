(require-macros :hibiscus.vim)

(local fmt string.format)
(local M {})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Config Paths
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set M.home vim.env.HOME)

(set M.config-path
  (fmt "%s/nvim" 
    (or 
      (os.getenv "XDG_CONFIG_DIR")
      (fmt "%s/.config" M.home))))

(set M.data-path
  (fmt "%s/nvim"
    (or 
      (os.getenv "XDG_DATA_DIR")
      (fmt "%s/.local/share" M.home))))

(set M.cache-path
  (fmt "%s/nvim"
    (or 
      (os.getenv "XDG_CACHE_DIR")
      (fmt "%s/.cache" M.home))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utility Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(lambda M.luastr [mod func]
  (fmt "<cmd>lua require(\"%s\").%s()<cr>" mod func))

(lambda M.cmdstr [cmd]
  (.. "<cmd>" cmd "<cr>"))

(lambda M.is-macos? []
  (let [uname (vim.loop.os_uname)]
    (= uname.sysname "Darwin")))

(lambda M.read-dir [dir]
  (->> 
    (-> 
      (vim.fn.globpath dir "*")
      (vim.split "\n"))
    (vim.tbl_map (lambda [file] (vim.fn.fnamemodify file ":t:r")))
    (vim.tbl_filter (lambda [file] (~= file "init")))))

:return M
