local register = require('core.pack').register_plugin
local readdir = require('core.helper').readdir
local fmt = string.format

local function get_configs()
  local configs = {}

  local dir = fmt('%s/lua/plugins', vim.fn.stdpath('config'))
  local configs = readdir(dir)

  for _, config in ipairs(configs) do
    conf = require(fmt("plugins.%s", config))
    configs = vim.tbl_extend('force', configs, conf)
  end

  return configs
end

local configs = get_configs()

local plugins = {
  -- Aesthetics [aesthetics.lua]
  {
    'sainnhe/gruvbox-material',
    config = configs.gruvbox_material
  },
  {
    'nvim-lualine/lualine.nvim',
    config = configs.lualine
  },
  {
    'glepnir/dashboard-nvim',
    config = configs.dashboard_nvim
  },

  -- Fuzzy Finder [telescope.lua]
  {
    'nvim-telescope/telescope.nvim',
    config   = configs.telescope,
    requires = {
      {'nvim-lua/popup.nvim'},
      {'nvim-lua/plenary.nvim'},
      {'nvim-telescope/telescope-fzy-native.nvim'},
      {'nvim-telescope/telescope-file-browser.nvim'}
    }
  },

  -- Treesitter [nvim-treesitter.lua]
  {
    'nvim-treesitter/nvim-treesitter',
    event    = 'BufRead',
    run      = ':TSUpdate',
    config   = configs.nvim_treesitter,
    requires = {{'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter' }}
  },

  -- LSP lsp.lua
  {'hrsh7th/cmp-nvim-lsp'},
  {
    'neovim/nvim-lspconfig',
    config   = configs.nvim_lspconfig,
    after    = 'cmp-nvim-lsp',
    requires = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'nvim-treesitter',
    }
  },
  {
    'glepnir/lspsaga.nvim',
    config = configs.lspsaga,
    after  = 'nvim-lspconfig'
  },

  -- Completion [completions.lua]
  {
    'L3MON4D3/LuaSnip',
    event  = 'InsertCharPre',
    config = configs.lua_snip
  },
  {
    'windwp/nvim-autopairs',
    config = configs.nvim_autopairs
  },
  {
    'hrsh7th/nvim-cmp',
    config   = configs.nvim_cmp,
    after    = {'nvim-autopairs'},
    requires = {
      { 'windwp/nvim-autopairs' },
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'saadparwaiz1/cmp_luasnip', after = 'LuaSnip' },
      { 'hrsh7th/cmp-buffer',       after = 'nvim-cmp' },
      { 'hrsh7th/cmp-path',         after = 'nvim-cmp' },
      { 'hrsh7th/cmp-cmdline',      after = 'nvim-cmp' }
    }
  },

  -- Movement improvements [movements.lua]
  {'junegunn/vim-easy-align'},
  {
    'kylechui/nvim-surround',
    config = configs.nvim_surround,
  },
  {
    'ggandor/leap.nvim',
    as       = 'leap',
    config   = configs.leap,
    requires = {'tpope/vim-repeat'}
  },
  {
    'ggandor/flit.nvim',
    config   = configs.flit,
    requires = {'leap'}
  },
  
  -- TMUX and windows
  {'alexghergh/nvim-tmux-navigation'},

  -- Git
  {
    'tpope/vim-fugitive',
    cmd = {'Git', 'Gdiff'}
  },

  -- Comment
  {
    'numToStr/Comment.nvim',
    event = 'BufEnter',
    config = configs.comment
  }
}

for _, plugin in ipairs(plugins) do
  register(plugin)
end
