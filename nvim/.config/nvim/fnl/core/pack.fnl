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
  ;; Performance
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :lewis6991/impatient.nvim)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Fennel
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :udayvir-singh/tangerine.nvim)

  (use! :udayvir-singh/hibiscus.nvim
        :requires ["udayvir-singh/tangerine.nvim"])

  (use! :Olical/conjure
        :ft [:clojure :fennel])

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Aesthetics
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :sainnhe/gruvbox-material
        :config #(color! :gruvbox-material))

  (use! :glepnir/dashboard-nvim
        :require "plugins/dashboard-nvim")


  (use! :nvim-lualine/lualine.nvim
        :config (setup! :lualine {:theme :gruvbox}))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; LSP Configurations
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :williamboman/mason.nvim
        :config (setup! :mason)
        :as "mason")

  (use! :williamboman/mason-lspconfig.nvim
        :config (setup! :mason-lspconfig)
        :after "mason"
        :as "mason-lspconfig")

  (use! :neovim/nvim-lspconfig
        :require "plugins/nvim-lspconfig"
        :after "mason-lspconfig"
        :requires [:hrsh7th/cmp-nvim-lsp])

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Movements
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :ggandor/leap.nvim
        :require "plugins/leap"
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

  (use! :ThePrimeagen/harpoon
        :require "plugins/harpoon"
        :requires [:nvim-lua/plenary.nvim])

  (use! :nvim-telescope/telescope.nvim
        :after "harpoon"
        :require "plugins/telescope"
        :requires [:nvim-lua/popup.nvim
                   :nvim-lua/plenary.nvim
                   :nvim-telescope/telescope-fzy-native.nvim
                   :nvim-telescope/telescope-file-browser.nvim])

  (use! :nvim-treesitter/nvim-treesitter
        :require "plugins/treesitter"
        :run "TSUpdate"
        :requires [:nvim-treesitter/nvim-treesitter-textobjects
                   :p00f/nvim-ts-rainbow])

  (use! :numToStr/Comment.nvim
        :config (setup! :Comment)
        :event "BufEnter")

  (use! :windwp/nvim-autopairs
        :config (setup! :nvim-autopairs {:disable_filetype [:TelescopePrompt :clojure :fennel]}))

  (use! "L3MON4D3/LuaSnip"
        :event "InsertCharPre"
        :require "plugins/luasnip"
        :requires [:rafamadriz/friendly-snippets])

  (use! :hrsh7th/nvim-cmp
        :require "plugins/nvim-cmp"
        :after "nvim-lspconfig"
        :requires [:saadparwaiz1/cmp_luasnip
                   :hrsh7th/cmp-buffer
                   :hrsh7th/cmp-path
                   :hrsh7th/cmp-cmdline])

  (use! :eraserhd/parinfer-rust
        :run "cargo build --release"
        :ft [:clojure :fennel])

  (use! :kylechui/nvim-surround
        :config (setup! :nvim-surround)))
 
(map! [n :verbose] "<leader>pu" (cmdstr :PackerUpdate))
(map! [n :verbose] "<leader>pi" (cmdstr :PackerInstall))
(map! [n :verbose] "<leader>pc" (cmdstr :PackerCompile))
(map! [n :verbose] "<leader>ps" (cmdstr :PackerSync))
