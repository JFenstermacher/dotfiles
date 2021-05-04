 return require('packer').startup(function() 
     
     -- Packer can manage itself as an optional plugin
     use { 'wbthomason/packer.nvim', opt = true }
     
     -- Color scheme
     use { 
       'sainnhe/gruvbox-material',
       config = function()
          vim.g.gruvbox_contrast_dark = 'hard'       
          vim.cmd 'colorscheme gruvbox-material'
       end
     }
 
     -- Fuzzy Finder
     use {
       'nvim-telescope/telescope.nvim',
       requires = {
         {'nvim-lua/popup.nvim', opt = true }, 
         {'nvim-lua/plenary.nvim', opt = true },
         {'nvim-telescope/telescope-fzy-native.nvim', opt = true }
       }
     }
 
 end)
