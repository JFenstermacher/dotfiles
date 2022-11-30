(require-macros :hibiscus.packer)

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
)
