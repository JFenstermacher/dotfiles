(require-macros :hibiscus.packer)
(import-macros {: map! : color!} :hibiscus.vim)
(import-macros {: fstring} :hibiscus.core)
(import-macros {: setup!} :core.macros)
(local {: cmdstr : data-path} (require "core.common"))

(packer-setup {:git
               {:clone_timeout 120}
               :display
               {:open_fn (. (require "packer.util") "float")
                :working_sym "ﰭ"
                :error_sym ""
                :done_sym ""
                :removed_sym ""
                :moved_sym "ﰳ"}})
(packer

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Fennel
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :udayvir-singh/tangerine.nvim)

  (use! :udayvir-singh/hibiscus.nvim
        :requires ["udayvir-singh/tangerine.nvim"])

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Aesthetics
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :sainnhe/gruvbox-material
        :config #(color! "gruvbox-material"))

  (use! :p00f/nvim-ts-rainbow)

  (use! :nvim-lualine/lualine.nvim
        :config (setup! "lualine" {:theme :gruvbox}))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; LSP Configurations
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :williamboman/mason.nvim
        :config (setup! "mason")
        :as "mason")

  (use! :williamboman/mason-lspconfig.nvim
        :config (setup! "mason-lspconfig")
        :after "mason"
        :as "mason-lspconfig")

  (use! :neovim/nvim-lspconfig
        :module "plugins/nvim-lspconfig"
        :after "mason-lspconfig"
        :requires ["hrsh7th/cmp-nvim-lsp"])

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Movements
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :ggandor/leap.nvim
        :module "plugins/leap"
        :as "leap")
  
  (use! :ggandor/flit.nvim
        :config (setup! :flit)
        :requires "leap")

  (use! :junegunn/vim-easy-align)

  (use! :alexghergh/nvim-tmux-navigation)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Git
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :tpope/vim-fugitive
        :cmd [:Git :Gdiff])

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Editor
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :nvim-telescope/telescope.nvim
        :module "plugins/telescope"
        :requires [:nvim-lua/popup.nvim
                   :nvim-lua/plenary.nvim
                   :nvim-telescope/telescope-fzy-native.nvim
                   :nvim-telescope/telescope-file-browser.nvim])

  (use! :nvim-treesitter/nvim-treesitter
        :module "plugins/treesitter"
        :run "TSUpdate")

  (use! :numToStr/Comment.nvim
        :config (setup! "Comment")
        :event "BufEnter")

  (use! :windwp/nvim-autopairs
        :config (setup! "nvim-autopairs" {:disable_filetype [:TelescopePrompt :clojure :fennel]}))

  (use! "L3MON4D3/LuaSnip"
        :event "InsertCharPre")

  (use! :hrsh7th/nvim-cmp
        :module "plugins/nvim-cmp"
        :after "nvim-lspconfig"
        :requires ["saadparwaiz1/cmp_luasnip"
                   "hrsh7th/cmp-buffer"
                   "hrsh7th/cmp-path"
                   "hrsh7th/cmp-cmdline"])

  (use! :eraserhd/parinfer-rust
        :run "cargo build --release"
        :ft ["clojure" "fennel"])

  (use! :kylechui/nvim-surround
        :config (setup! "nvim-surround")))
 

(map! [n] "<leader>pu" (cmdstr "PackerUpdate"))
(map! [n] "<leader>pi" (cmdstr "PackerInstall"))
(map! [n] "<leader>pc" (cmdstr "PackerCompile"))
(map! [n] "<leader>ps" (cmdstr "PackerSync"))
