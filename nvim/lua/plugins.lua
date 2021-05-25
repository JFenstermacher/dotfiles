local packer = nil
local configs = nil

local function init()
  if packer == nil then
    packer = require('packer')
    packer.init({ disable_commands = true })
  end
  
  if configs == nil then
    configs = require('configs')
  end

  local use = packer.use
  packer.reset()

  -- Packer can manage itself as an optional plugin
  use { 'wbthomason/packer.nvim', opt = true }

  -- Color scheme
  use { 'sainnhe/gruvbox-material' }

  -- Fuzzy Finder
  use {
    'nvim-telescope/telescope.nvim',
    setup = configs['telescope'].setup,
    config = configs['telescope'].config,
    requires = {
      {'nvim-lua/popup.nvim' },
      {'nvim-lua/plenary.nvim' },
      {'nvim-telescope/telescope-fzy-native.nvim' }
    }
  }

  -- Easy Align
  use {
    'junegunn/vim-easy-align',
    config = configs['vim-easy-align'].config
  }

  -- Terminal
  use {
    'voldikss/vim-floaterm',
    config = configs['vim-floaterm'].config
  }

  -- LSP
  use {
    'neovim/nvim-lspconfig',
    'kabouzeid/nvim-lspinstall',
    'glepnir/lspsaga.nvim',
    'onsails/lspkind-nvim'
  }

  use {
    'hrsh7th/nvim-compe',
    config = configs['nvim-compe'].config
  }

  -- Undo
  use {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    config = [[vim.g.undotree_SetFocusWhenToggle = 1]]
  }

end

local plugins = setmetatable({}, {
  __index = function(_, key)
    init()
    return packer[key]
  end
})

return plugins
