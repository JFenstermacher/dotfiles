local execute = vim.api.nvim_command
local fn = vim.fn
local fmt = string.format

local function init()
  local install_path = fmt('%s/site/pack/packer/start/packer.nvim', fn.stdpath('data'))

  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
    execute 'packadd packer.nvim'
  end

  return require 'packer'
end

local function safeload(name)
  local path = fmt('plugins.%s', name)

  local ok, err = pcall(function() require(path) end)

  if not ok then
    print("Dotfiles error: " .. err)
  end
end

local function use(plugins)
  local packer = init()

  packer.startup(function()
    local bind = require('keymaps').bind_plugin

    for repo, plugin in pairs(plugins) do
      plugin[1] = repo

      if plugin.as then
        plugin.config = safeload(plugin.as)
      end

      packer.use(plugin)

      bind(repo)
    end
  end)
end

use{
  -- Packer
  ['wbthomason/packer.nvim'] = { opt = true },

  -- Color Scheme
  ['sainnhe/gruvbox-material'] = { config = [[vim.cmd('colorscheme gruvbox-material')]] },

  ['glepnir/dashboard-nvim'] = { as = "dashboard" },

  -- Telescope
  ['nvim-telescope/telescope.nvim'] = {
    as = 'telescope',
    requires = {
      {'nvim-lua/popup.nvim'},
      {'nvim-lua/plenary.nvim'},
      {'nvim-telescope/telescope-fzy-native.nvim'},
    }
  },

  -- Git
  ['tpope/vim-fugitive'] = {
    cmd = { 'Git', 'Gdiff' },
  },

  -- LSP
  ['neovim/nvim-lspconfig'] = {
    as = 'lsp',
    requires = {{'williamboman/nvim-lsp-installer'}}
  },

  -- Treesitter
  ['nvim-treesitter/nvim-treesitter'] = {
    as = "treesitter",
    run = ":TSUpdate"
  },

  -- Complete
  ['hrsh7th/nvim-cmp'] = {
    as = 'cmp',
    requires = {
      {'windwp/nvim-autopairs'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'hrsh7th/cmp-cmdline'},
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-vsnip'},
      {'hrsh7th/vim-vsnip'}
    }
  },

  -- Comments
  ['tpope/vim-commentary'] = {},

  -- Movements Improvement
  ['junegunn/vim-easy-align'] = { as = 'easy-align' },
  ['justinmk/vim-sneak'] = { as = 'sneak' },
  ['tpope/vim-vinegar'] = {},
  ['tpope/vim-surround'] = {},

  -- Database
  ['kristijanhusak/vim-dadbod-ui'] = {
    as = "dadbod",
    cmd = { 'DBUIToggle', 'DBUIAddConnection', 'DBUI', 'DBUIFindBuffer', 'DBUIRenameBuffer' },
    requires = {
      { 'tpope/vim-dadbod' },
      { 'kristijanhusak/vim-dadbod-completion' }
    }
  },

  -- Status Line
  ['nvim-lualine/lualine.nvim'] = { as = 'lualine' },

  -- Tmux Navigation
  ['christoomey/vim-tmux-navigator'] = {
    config = function()
      vim.api.nvim_command [[autocmd VimResized * :wincmd =]]
    end
  },

  ['christoomey/vim-tmux-runner'] = {
    as = "vim-tmux-runner"
  },

  ['ahmedkhalf/project.nvim'] = {
    as = 'project'
  }
}
