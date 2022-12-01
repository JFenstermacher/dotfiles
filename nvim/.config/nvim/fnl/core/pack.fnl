(require-macros :hibiscus.packer)
(import-macros {: map!} :hibiscus.vim)
(local {: cmdstr} (require "core.common"))

(packer-setup)

(packer
  (use! :udayvir-singh/tangerine.nvim)

  (use! :udayvir-singh/hibiscus.nvim
        :requires ["udayvir-singh/tangerine.nvim"])

  (use! :alexghergh/nvim-tmux-navigation)

  (use! :sainnhe/gruvbox-material
        :module "plugins/gruvbox-material")

  (use! :nvim-telescope/telescope.nvim
        :module "plugins/telescope"
        :requires ["nvim-lua/popup.nvim"
                   "nvim-lua/plenary.nvim"
                   "nvim-telescope/telescope-fzy-native.nvim"
                   "nvim-telescope/telescope-file-browser.nvim"])

  (use! :nvim-treesitter/nvim-treesitter
        :module "plugins/treesitter"
        :run "TSUpdate")

  (use! :numToStr/Comment.nvim
        :module "plugins/comment"
        :event "BufEnter")

  (use! :windwp/nvim-autopairs
        :module "plugins/nvim-autopairs")

  (use! :junegunn/vim-easy-align)

  (use! :ggandor/leap.nvim
        :module "plugins/leap"
        :as "leap")
  
  (use! :ggandor/flit.nvim
        :module "plugins/flit"
        :requires "leap")

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; LSP Configurations
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (use! :williamboman/mason.nvim
        :module "plugins/mason"
        :as "mason")

  (use! :williamboman/mason-lspconfig.nvim
        :module "plugins/mason-lspconfig"
        :after "mason"
        :as "mason-lspconfig")

  (use! :neovim/nvim-lspconfig
        :module "plugins/nvim-lspconfig"
        :after "mason-lspconfig")
)

(map! [n] "<leader>pu" (cmdstr "PackerUpdate"))
(map! [n] "<leader>pi" (cmdstr "PackerInstall"))
(map! [n] "<leader>pc" (cmdstr "PackerCompile"))
