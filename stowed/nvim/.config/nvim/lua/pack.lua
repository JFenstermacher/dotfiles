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
    for repo, plugin in pairs(plugins) do
      plugin[1] = repo

      if plugin.as then
        plugin.config = safeload(plugin.as)
      end

      packer.use(plugin)
    end
  end)
end

use{
  -- Packer
  ['wbthomason/packer.nvim'] = { opt = true },

  -- Color Scheme
  ['sainnhe/gruvbox-material'] = { config = [[vim.cmd('colorscheme gruvbox-material')]] },

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
    as = 'fugitive'
  },

  -- LSP
  ['neovim/nvim-lspconfig'] = {
    as = 'lsp',
    requires = {{'kabouzeid/nvim-lspinstall'}}
  },

  -- Treesitter
  ['nvim-treesitter/nvim-treesitter'] = {
    as = "treesitter",
    run = ":TSUpdate"
  },

  -- Complete
  ['hrsh7th/nvim-compe'] = {
    as = 'compe',
    requires = {{'windwp/nvim-autopairs'}}
  },

  -- Comments
  ['tpope/vim-commentary'] = {},

  -- Movements Improvement
  ['junegunn/vim-easy-align'] = { as = 'easy-align' },
  ['hrsh7th/vim-eft'] = { as = 'eft' },
  ['justinmk/vim-sneak'] = {},
  ['tpope/vim-vinegar'] = {},
  ['tpope/vim-surround'] = {},

  -- Database
  ['kristijanhusak/vim-dadbod'] = {
    cmd = { 'DBUIToggle', 'DBUIAddConnection', 'DBUI', 'DBUIFindBuffer', 'DBUIRenameBuffer' },
    requires = {
      { 'tpope/vim-dadbod', opt = true },
      { 'kristijanhusak/vim-dadbod-completion', opt = true }
    }
  },

  -- Terminal
  ['voldikss/vim-floaterm'] = {
    cmd = { 'FloatermNew', 'FloatermToggle', 'FloatermNext', 'FloatermPrev', 'FloatermKill' },
    as = 'floaterm'
  }
}
